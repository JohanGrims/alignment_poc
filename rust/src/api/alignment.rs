use flutter_rust_bridge::frb;
use ort::session::Session;
use ort::value::Value;
use std::sync::RwLock;
use tokenizers::Tokenizer;

// Global state for model and tokenizer to avoid reloading
lazy_static::lazy_static! {
    static ref MODEL: RwLock<Option<Session>> = RwLock::new(None);
    static ref TOKENIZER: RwLock<Option<Tokenizer>> = RwLock::new(None);
    static ref EMBEDDING_CACHE: RwLock<std::collections::HashMap<String, Vec<f32>>> = RwLock::new(std::collections::HashMap::new());
}

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn clear_cache() {
    EMBEDDING_CACHE.write().unwrap().clear();
}

pub fn load_model(onnx_path: String, tokenizer_path: String) -> Result<(), String> {
    let tokenizer = Tokenizer::from_file(&tokenizer_path).map_err(|e| e.to_string())?;
    *TOKENIZER.write().unwrap() = Some(tokenizer);

    let session = Session::builder()
        .map_err(|e| e.to_string())?

        .commit_from_file(&onnx_path)
        .map_err(|e| e.to_string())?;
        
    *MODEL.write().unwrap() = Some(session);
    Ok(())
}

fn compute_embeddings(texts: &[String]) -> Result<Vec<Vec<f32>>, String> {
    if texts.is_empty() { return Ok(Vec::new()); }
    
    let mut final_embeddings = vec![Vec::new(); texts.len()];
    let mut texts_to_compute = Vec::new();
    let mut indices_to_compute = Vec::new();
    
    {
        let cache = EMBEDDING_CACHE.read().unwrap();
        for (i, text) in texts.iter().enumerate() {
            if let Some(emb) = cache.get(text) {
                final_embeddings[i] = emb.clone();
            } else {
                texts_to_compute.push(text.clone());
                indices_to_compute.push(i);
            }
        }
    }
    
    if texts_to_compute.is_empty() {
        return Ok(final_embeddings);
    }
    
    let tok_guard = TOKENIZER.read().unwrap();
    let tokenizer = tok_guard.as_ref().ok_or("Tokenizer not loaded")?;
    let mut mod_guard = MODEL.write().unwrap();
    let model = mod_guard.as_mut().ok_or("Model not loaded")?;

    let batch_size = texts_to_compute.len();
    let mut encodings = Vec::with_capacity(batch_size);
    let mut max_len = 0;
    
    for text in &texts_to_compute {
        let encoding = tokenizer.encode(text.as_str(), true).map_err(|e| e.to_string())?;
        max_len = std::cmp::max(max_len, encoding.get_ids().len());
        encodings.push(encoding);
    }
    
    let mut input_ids = vec![0i64; batch_size * max_len];
    let mut attention_mask = vec![0i64; batch_size * max_len];
    let mut token_type_ids = vec![0i64; batch_size * max_len];
    
    for (i, encoding) in encodings.iter().enumerate() {
        let ids = encoding.get_ids();
        let mask = encoding.get_attention_mask();
        let types = encoding.get_type_ids();
        let len = ids.len();
        
        for j in 0..len {
            let idx = i * max_len + j;
            input_ids[idx] = ids[j] as i64;
            attention_mask[idx] = mask[j] as i64;
            token_type_ids[idx] = types[j] as i64;
        }
    }
    
    let input_ids_array = ndarray::Array2::from_shape_vec((batch_size, max_len), input_ids).unwrap();
    let attention_mask_array = ndarray::Array2::from_shape_vec((batch_size, max_len), attention_mask).unwrap();
    let token_type_ids_array = ndarray::Array2::from_shape_vec((batch_size, max_len), token_type_ids).unwrap();

    let inputs = ort::inputs![
        "input_ids" => Value::from_array(input_ids_array).unwrap(),
        "attention_mask" => Value::from_array(attention_mask_array).unwrap(),
        "token_type_ids" => Value::from_array(token_type_ids_array).unwrap(),
    ];

    let outputs = model.run(inputs).map_err(|e| e.to_string())?;
    let output = outputs["last_hidden_state"].try_extract_tensor::<f32>().map_err(|e| e.to_string())?;
    
    let flat_output = output.1;
    let mut new_embeddings = Vec::with_capacity(batch_size);
    
    for i in 0..batch_size {
        let mut sum_embedding = vec![0.0; 384]; // miniLM is 384
        let mut valid_tokens = 0;
        let encoding_mask = encodings[i].get_attention_mask();
        
        for j in 0..encodings[i].get_ids().len() {
            if encoding_mask[j] == 1 {
                for d in 0..384 {
                    sum_embedding[d] += flat_output[i * max_len * 384 + j * 384 + d];
                }
                valid_tokens += 1;
            }
        }
        
        if valid_tokens > 0 {
            let mut norm = 0.0;
            for d in 0..384 {
                sum_embedding[d] /= valid_tokens as f32;
                norm += sum_embedding[d] * sum_embedding[d];
            }
            norm = norm.sqrt();
            for d in 0..384 {
                sum_embedding[d] /= norm.max(1e-9);
            }
        }
        new_embeddings.push(sum_embedding);
    }
    
    let mut cache = EMBEDDING_CACHE.write().unwrap();
    for (k, emb) in new_embeddings.into_iter().enumerate() {
        let orig_idx = indices_to_compute[k];
        final_embeddings[orig_idx] = emb.clone();
        cache.insert(texts_to_compute[k].clone(), emb);
    }
    
    Ok(final_embeddings)
}

fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    let mut dot = 0.0;
    for (x, y) in a.iter().zip(b.iter()) {
        dot += x * y;
    }
    dot
}

#[derive(Clone, Debug)]
pub struct AlignmentPair {
    pub source_indices: Vec<i32>,
    pub target_indices: Vec<i32>,
    pub score: f32,
}

pub fn align_sentences(source_sentences: Vec<String>, target_sentences: Vec<String>, max_align: u32) -> Result<Vec<AlignmentPair>, String> {
    let max_align = max_align as usize;
    // 1. Compute embeddings for all blocks
    // In a real scenario, overlap and block caching would be heavily optimized.
    let n = source_sentences.len();
    let m = target_sentences.len();
    
    let mut dp = vec![vec![f32::INFINITY; m + 1]; n + 1];
    let mut backptr = vec![vec![(0, 0); m + 1]; n + 1];
    
    dp[0][0] = 0.0;
    
    // Precompute block embeddings to save time
    let mut src_emb = std::collections::HashMap::new();
    let mut tgt_emb = std::collections::HashMap::new();
    
    // Prepare batched inputs for source
    let mut src_texts = Vec::new();
    let mut src_keys = Vec::new();
    for i in 0..n {
        for len in 1..=max_align {
            if i + len <= n {
                src_texts.push(source_sentences[i..i+len].join(" "));
                src_keys.push((i, len));
            }
        }
    }
    
    // Process source batches
    let batch_size = 32;
    let chunks_texts: Vec<_> = src_texts.chunks(batch_size).collect();
    let chunks_keys: Vec<_> = src_keys.chunks(batch_size).collect();
    for i in 0..chunks_texts.len() {
        if let Ok(embs) = compute_embeddings(chunks_texts[i]) {
            for (key, emb) in chunks_keys[i].iter().zip(embs.into_iter()) {
                src_emb.insert(*key, emb);
            }
        }
    }
    
    // Prepare batched inputs for target
    let mut tgt_texts = Vec::new();
    let mut tgt_keys = Vec::new();
    for j in 0..m {
        for len in 1..=max_align {
            if j + len <= m {
                tgt_texts.push(target_sentences[j..j+len].join(" "));
                tgt_keys.push((j, len));
            }
        }
    }
    
    // Process target batches
    let chunks_tgt_texts: Vec<_> = tgt_texts.chunks(batch_size).collect();
    let chunks_tgt_keys: Vec<_> = tgt_keys.chunks(batch_size).collect();
    for i in 0..chunks_tgt_texts.len() {
        if let Ok(embs) = compute_embeddings(chunks_tgt_texts[i]) {
            for (key, emb) in chunks_tgt_keys[i].iter().zip(embs.into_iter()) {
                tgt_emb.insert(*key, emb);
            }
        }
    }
    
    // Allowed transitions (source_len, target_len)
    let transitions = vec![
        (1, 1), (1, 0), (0, 1),
        (2, 0), (0, 2), (3, 0), (0, 3),
        (2, 1), (1, 2), (2, 2),
        (3, 1), (1, 3), (3, 2), (2, 3), (3, 3)
    ];

    let window_size = 30; // Banding corridor width
    
    for i in 0..=n {
        let expected_j = if n > 0 { (i as f32 / n as f32 * m as f32) as usize } else { 0 };
        let min_j = expected_j.saturating_sub(window_size);
        let max_j = std::cmp::min(m, expected_j + window_size);
        
        for j in min_j..=max_j {
            if dp[i][j] == f32::INFINITY { continue; }
            
            for &(di, dj) in &transitions {
                if di > max_align || dj > max_align { continue; }
                if i + di <= n && j + dj <= m {
                    let expected_dest_j = if n > 0 { ((i + di) as f32 / n as f32 * m as f32) as usize } else { 0 };
                    let dest_j = j + dj;
                    if dest_j < expected_dest_j.saturating_sub(window_size) || dest_j > std::cmp::min(m, expected_dest_j + window_size) {
                        continue;
                    }
                    let cost = if di == 0 || dj == 0 {
                        // Deletion/Insertion penalty (block scaled)
                        // Linear scale: 0.4 per sentence
                        0.4 * (di + dj) as f32
                    } else {
                        // Match cost
                        let s_emb = src_emb.get(&(i, di));
                        let t_emb = tgt_emb.get(&(j, dj));
                        if let (Some(s), Some(t)) = (s_emb, t_emb) {
                            let sim = cosine_similarity(s, t);
                            (1.0 - sim) * ((di + dj) as f32 / 2.0)
                        } else {
                            f32::INFINITY
                        }
                    };
                    
                    let new_cost = dp[i][j] + cost;
                    if new_cost < dp[i + di][j + dj] {
                        dp[i + di][j + dj] = new_cost;
                        backptr[i + di][j + dj] = (di, dj);
                    }
                }
            }
        }
    }
    
    let mut alignments = Vec::new();
    let mut i = n;
    let mut j = m;
    
    while i > 0 || j > 0 {
        let (di, dj) = backptr[i][j];
        if di == 0 && dj == 0 {
            return Err("Failed to align".into());
        }
        
        let src_indices: Vec<i32> = (i - di..i).map(|x| x as i32).collect();
        let tgt_indices: Vec<i32> = (j - dj..j).map(|x| x as i32).collect();
        
        alignments.push(AlignmentPair {
            source_indices: src_indices,
            target_indices: tgt_indices,
            score: dp[i][j] - dp[i - di][j - dj],
        });
        
        i -= di;
        j -= dj;
    }
    
    alignments.reverse();
    Ok(alignments)
}

pub fn align_words_greedy(source_words: Vec<String>, target_words: Vec<String>, threshold: f32) -> Result<Vec<AlignmentPair>, String> {
    if source_words.is_empty() || target_words.is_empty() {
        return Ok(Vec::new());
    }

    let src_embs = compute_embeddings(&source_words)?;
    let tgt_embs = compute_embeddings(&target_words)?;

    let n = source_words.len();
    let m = target_words.len();

    // 1. Compute all similarities and store as edges
    let mut edges = Vec::new();
    for i in 0..n {
        for j in 0..m {
            let sim = cosine_similarity(&src_embs[i], &tgt_embs[j]);
            if sim >= threshold {
                edges.push((sim, i, j));
            }
        }
    }

    // 2. Sort edges descending by similarity
    edges.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));

    // 3. Union-Find / Component Tracking with Degree Constraints
    let mut parent = (0..(n + m)).collect::<Vec<usize>>();
    let mut comp_size = vec![1; n + m];
    let mut degree = vec![0; n + m];

    fn find(mut i: usize, parent: &mut Vec<usize>) -> usize {
        while i != parent[i] {
            parent[i] = parent[parent[i]];
            i = parent[i];
        }
        i
    }

    let mut final_edges = Vec::new();

    for (sim, i, j) in edges {
        let u = i;
        let v = n + j;

        if degree[u] >= 2 || degree[v] >= 2 {
            continue; // Prevent a single word from acting as a massive hub
        }

        let root_u = find(u, &mut parent);
        let root_v = find(v, &mut parent);

        if root_u != root_v {
            if comp_size[root_u] + comp_size[root_v] <= 4 {
                parent[root_u] = root_v;
                comp_size[root_v] += comp_size[root_u];
                
                degree[u] += 1;
                degree[v] += 1;
                final_edges.push((i, j, sim));
            }
        }
    }

    // 4. Extract Components
    let mut comp_map: std::collections::HashMap<usize, (Vec<i32>, Vec<i32>, f32, i32)> = std::collections::HashMap::new();
    
    for i in 0..n {
        let root = find(i, &mut parent);
        comp_map.entry(root).or_insert((Vec::new(), Vec::new(), 0.0, 0)).0.push(i as i32);
    }
    for j in 0..m {
        let root = find(n + j, &mut parent);
        comp_map.entry(root).or_insert((Vec::new(), Vec::new(), 0.0, 0)).1.push(j as i32);
    }

    for (i, _, sim) in final_edges {
        let root = find(i, &mut parent);
        if let Some(entry) = comp_map.get_mut(&root) {
            entry.2 += sim;
            entry.3 += 1;
        }
    }

    let mut alignments = Vec::new();
    for (_, (mut src, mut tgt, sum_sim, count)) in comp_map {
        if !src.is_empty() && !tgt.is_empty() {
            src.sort_unstable();
            tgt.sort_unstable();
            let avg_sim = if count > 0 { sum_sim / count as f32 } else { 0.0 };
            alignments.push(AlignmentPair {
                source_indices: src,
                target_indices: tgt,
                score: 1.0 - avg_sim, // Cost
            });
        }
    }

    Ok(alignments)
}

pub struct WordSpan {
    pub start: i32,
    pub end: i32,
    pub text: String,
}

pub fn align_words_contextual(
    source_text: String,
    source_spans: Vec<WordSpan>,
    target_text: String,
    target_spans: Vec<WordSpan>,
    threshold: f32,
) -> Result<Vec<AlignmentPair>, String> {
    if source_spans.is_empty() || target_spans.is_empty() {
        return Ok(Vec::new());
    }

    let tok_guard = TOKENIZER.read().unwrap();
    let tokenizer = tok_guard.as_ref().ok_or("Tokenizer not loaded")?;
    let mut mod_guard = MODEL.write().unwrap();
    let model = mod_guard.as_mut().ok_or("Model not loaded")?;

    let src_encoding = tokenizer.encode(source_text.as_str(), true).map_err(|e| e.to_string())?;
    let tgt_encoding = tokenizer.encode(target_text.as_str(), true).map_err(|e| e.to_string())?;

    let mut get_embeddings = |encoding: &tokenizers::Encoding, spans: &Vec<WordSpan>| -> Result<Vec<Vec<f32>>, String> {
        let max_len = encoding.get_ids().len();
        
        let mut input_ids = vec![0i64; max_len];
        let mut attention_mask = vec![0i64; max_len];
        let mut token_type_ids = vec![0i64; max_len];
        
        for j in 0..max_len {
            input_ids[j] = encoding.get_ids()[j] as i64;
            attention_mask[j] = encoding.get_attention_mask()[j] as i64;
            token_type_ids[j] = encoding.get_type_ids()[j] as i64;
        }

        let input_ids_array = ndarray::Array2::from_shape_vec((1, max_len), input_ids).unwrap();
        let attention_mask_array = ndarray::Array2::from_shape_vec((1, max_len), attention_mask).unwrap();
        let token_type_ids_array = ndarray::Array2::from_shape_vec((1, max_len), token_type_ids).unwrap();

        let inputs = ort::inputs![
            "input_ids" => Value::from_array(input_ids_array).unwrap(),
            "attention_mask" => Value::from_array(attention_mask_array).unwrap(),
            "token_type_ids" => Value::from_array(token_type_ids_array).unwrap(),
        ];

        let outputs = model.run(inputs).map_err(|e| e.to_string())?;
        let output = outputs["last_hidden_state"].try_extract_tensor::<f32>().map_err(|e| e.to_string())?;
        let flat_output = output.1; // size is [1, max_len, 384]

        let offsets = encoding.get_offsets();

        let mut word_embs = Vec::with_capacity(spans.len());
        for span in spans {
            let mut sum_embedding = vec![0.0; 384];
            let mut valid_tokens = 0;
            
            for j in 0..max_len {
                let off = offsets[j];
                // Ignore special tokens (offset 0,0 usually, or just bounds check)
                if off.0 == 0 && off.1 == 0 { continue; }
                
                // Overlap check
                if off.0 < span.end as usize && off.1 > span.start as usize {
                    for d in 0..384 {
                        sum_embedding[d] += flat_output[j * 384 + d];
                    }
                    valid_tokens += 1;
                }
            }
            
            if valid_tokens > 0 {
                let mut norm = 0.0;
                for d in 0..384 {
                    sum_embedding[d] /= valid_tokens as f32;
                    norm += sum_embedding[d] * sum_embedding[d];
                }
                norm = norm.sqrt();
                for d in 0..384 {
                    sum_embedding[d] /= norm.max(1e-9);
                }
            }
            word_embs.push(sum_embedding);
        }
        
        Ok(word_embs)
    };

    let src_embs = get_embeddings(&src_encoding, &source_spans)?;
    let tgt_embs = get_embeddings(&tgt_encoding, &target_spans)?;

    let n = source_spans.len();
    let m = target_spans.len();

    let mut edges = Vec::new();
    for i in 0..n {
        for j in 0..m {
            let sim = cosine_similarity(&src_embs[i], &tgt_embs[j]);
            if sim >= threshold {
                edges.push((sim, i, j));
            }
        }
    }

    edges.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));

    let mut parent = (0..(n + m)).collect::<Vec<usize>>();
    let mut comp_size = vec![1; n + m];
    let mut degree = vec![0; n + m];

    fn find(mut i: usize, parent: &mut Vec<usize>) -> usize {
        while i != parent[i] {
            parent[i] = parent[parent[i]];
            i = parent[i];
        }
        i
    }

    let mut final_edges = Vec::new();

    for (sim, i, j) in edges {
        let u = i;
        let v = n + j;

        if degree[u] >= 2 || degree[v] >= 2 {
            continue;
        }

        // --- N:M Penalty ---
        // Reward 1:1 mappings by penalizing edges that attach to already mapped nodes.
        // If a node already has 1 edge, it costs a penalty of 0.15 to add a second edge.
        let penalty = 0.15 * (degree[u] + degree[v]) as f32;
        if sim - penalty < threshold {
            continue;
        }

        let root_u = find(u, &mut parent);
        let root_v = find(v, &mut parent);

        if root_u != root_v {
            if comp_size[root_u] + comp_size[root_v] <= 4 {
                parent[root_u] = root_v;
                comp_size[root_v] += comp_size[root_u];
                
                degree[u] += 1;
                degree[v] += 1;
                final_edges.push((i, j, sim));
            }
        }
    }

    let mut comp_map: std::collections::HashMap<usize, (Vec<i32>, Vec<i32>, f32, i32)> = std::collections::HashMap::new();
    
    for i in 0..n {
        let root = find(i, &mut parent);
        comp_map.entry(root).or_insert((Vec::new(), Vec::new(), 0.0, 0)).0.push(i as i32);
    }
    for j in 0..m {
        let root = find(n + j, &mut parent);
        comp_map.entry(root).or_insert((Vec::new(), Vec::new(), 0.0, 0)).1.push(j as i32);
    }

    for (i, _, sim) in final_edges {
        let root = find(i, &mut parent);
        if let Some(entry) = comp_map.get_mut(&root) {
            entry.2 += sim;
            entry.3 += 1;
        }
    }

    let mut alignments = Vec::new();
    for (_, (mut src, mut tgt, sum_sim, count)) in comp_map {
        if !src.is_empty() && !tgt.is_empty() {
            src.sort_unstable();
            tgt.sort_unstable();
            let avg_sim = if count > 0 { sum_sim / count as f32 } else { 0.0 };
            alignments.push(AlignmentPair {
                source_indices: src,
                target_indices: tgt,
                score: 1.0 - avg_sim, // Cost
            });
        }
    }

    Ok(alignments)
}
