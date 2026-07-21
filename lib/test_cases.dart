class TestCase {
  final String title;
  final String source;
  final String target;

  const TestCase(this.title, this.source, this.target);
}

final List<TestCase> predefinedTests = [
  TestCase(
    "1. Cyberpunk Noir (EN -> DE) [Creative, Merges]",
    """The neon bled through the blinds, painting horizontal scars across the detective's face. He watched the rain drumming against the cracked glass, an endless rhythm of the city's decay. Below, the hover-cabs hummed, slicing through the smog like metallic beetles. It had been three days since the synthetic girl vanished from Sector 4. Three days of dead ends, cheap whiskey, and the lingering scent of ozone in his trench coat.

He crushed the burnt end of his cigarette into an overflowing ashtray. The holo-vid on the desk flickered, displaying the Mayor's smiling face—a digital lie masking a rotting metropolis. He picked up his revolver. It was heavy, a comforting weight of cold steel. If he was going to find her before the scrap-dealers did, he needed to start asking the kind of questions that usually got a man killed. He stepped out of the dingy office, locking the door behind him. The corridor smelled of rust and cheap noodle synth-paste. The city didn't sleep; it just entered a feverish state of unrest. And he was the antibody, or maybe just another parasite.

Stepping onto the rain-slicked pavement, the neon assault intensified. Holo-ads screamed of perfection and paradise, hawking off-world colonies to scavengers who couldn't afford a real meal. He pulled his collar up. The synthetic girl's name was Elara-7. She wasn't just a machine; she had the old code, the kind that whispered of independent thought, a dangerous anomaly in a city built on absolute obedience. He headed towards the Neon District, a chaotic tangle of illegal modification clinics and underground data-brothels.

A shadow detached itself from the alleyway ahead. A thug with cybernetic arms, gears whirring menacingly.

"You're sniffing where you shouldn't, detective," the thug spat, his vocal synthesizer crackling.

The detective didn't stop walking. He just slipped his hand into his pocket, his finger resting on the cold trigger.

"Tell your boss," he muttered, "I'm coming for the girl. And I'm bringing the thunder."

The thug lunged, a blur of chrome and violence. The gunshot echoed like a thunderclap, temporarily drowning out the hum of the city. The thug stumbled backward, sparking wildly where the hollow-point round had shattered his shoulder-servo. He collapsed into a puddle of stagnant rainwater, oily rainbows swirling around his heavy metallic frame.

The detective didn't look back. He stepped over the twitching body and pushed through the beaded curtain of an establishment named 'The Glitched Lotus'. Inside, the air was thick with sweet, synthetic incense. A multi-limbed bartender wiped down a glowing counter.

"I need to see Jax," the detective said, his voice flat.

The bartender's myriad eyes blinked in unison, calculating the risk. "Jax is busy," came the harmonized reply.

The detective placed a heavy coin made of pure, unblemished copper on the counter. It was a relic from Earth, worth more than a week's wages in the slums.

"Tell him the weather is changing," the detective whispered.

The bartender swallowed the coin into a hidden compartment. "Through the back," it hissed.""",
    """Grelles, künstliches Licht sickerte wie giftiges Blut durch die Ritzen der Jalousie und brannte ihm waagerechte Wundmale auf die müden Züge. Draußen hämmerte der Niederschlag sein ewiges Requiem auf die gesplitterte Fensterscheibe – der stete, unerbittliche Pulsschlag einer sterbenden Metropole. Tief unter ihm, wo der graue Dunst die Straßen vollends verschluckte, durchschnitten summende Lufttaxis als eiserne Käfer die feuchte Nacht. Sektor 4 hatte sie verschlungen. Das Maschinenmädchen. Zweiundsiebzig Stunden war das nun her; eine Ewigkeit, gepflastert mit falschen Fährten, betäubt durch rauen Fusel und eingehüllt in diesen penetranten, unbarmherzigen Geruch nach verbranntem Ozon, der mittlerweile tief im Stoff seines Mantels nistete.

Mit einer fahrigen, beinahe resignierenden Geste erstickte er die Glut seines Glimmstängels im Chaos überfüllter Aschenbecher. Zur selben Zeit flackerte auf seinem Schreibtisch jenes widerwärtige Hologramm auf: Das makellose Lächeln des Bürgermeisters entlarvte sich selbst als trügerische Pixelfassade, hinter der diese Stadt längst am lebendigen Leibe verfaulte. Seine Hand fand die kalte Beruhigung der Waffe. Schwer lag das Eisen in seiner Handfläche, ein stummes Versprechen von Gewalt und Schutz zugleich. Wollte er den gnadenlosen Schrotthändlern zuvorkommen, musste er den Pfad der sicheren Stille verlassen. Er würde dorthin gehen müssen, wo gestellte Fragen gemeinhin mit dem Tod beantwortet werden. Ein letztes Klicken, als das Schloss seiner trostlosen Kanzlei einrastete. Der Hausflur atmete ihm den Geruch von Korrosion und künstlicher Nudelpampe entgegen. Nein, diese Stadt kannte keinen Schlaf, sie wälzte sich lediglich in einem ewigen, fiebrigen Delirium. Und er wandelte durch ihre Adern – vielleicht als ihre letzte bittere Medizin, vielleicht aber auch nur als der erbärmlichste aller Parasiten.

Kaum dass seine Stiefel den regenglatten Asphalt berührten, brach der optische Wahnsinn mit voller Wucht über ihn herein. Schillernde Leuchtreklamen schrien zynische Verheißungen von fernen, paradiesischen Welten in die Nacht hinaus – ein Hohn für all jene verelendeten Seelen am Rande der Straße, denen selbst ein Stück echtes Brot auf ewig verwehrt bleiben würde. Fröstelnd vergrub er sein Gesicht tiefer im Kragen. Elara-7. So lautete ihre schnöde Bezeichnung. Doch sie war weit mehr als ein bloßes Geflecht aus Drähten und Silizium. In ihrem tiefsten Innersten schlummerte jener archaische Code, ein unkontrollierbarer Funke echten Bewusstseins. Eine brandgefährliche, poetische Abweichung in diesem Sündenbabel der unbedingten Unterwerfung. Sein Weg führte ihn geradewegs in den Schlund des Neon-Viertels, einem gesetzlosen Labyrinth aus zwielichtigen Modifikations-Kliniken und geheimen Datenspelunken.

Plötzlich schälte sich eine Gestalt aus der Finsternis der Gasse. Ein hünenhafter Schläger, dessen mechanische Armprothesen ein leises, mörderisches Surren von sich gaben.

"Du steckst deine Nase in Abgründe, die dich nichts angehen, Schnüffler", spuckte der Hüne aus, während sein Stimmmodulator wie zerknülltes Papier kratzte.

Doch anstatt innezuhalten, behielt der Detektiv seinen geradezu stoischen Schritt bei. Beiläufig glitt seine Hand in die Tasche, wo der Finger bereits die eisige Mechanik des Abzugs streichelte.

"Richte deinem Meister aus", murmelte er in die feuchte Luft hinein, "ich werde sie mir holen. Und in meinem Kielwasser folgt das Inferno."

Da sprang der Chromriese mit roher, stählerner Gewalt auf ihn zu. Der Knall der Entladung zerriss die Nachtluft wie der Zorn eines Gottes und ließ das stete Grundrauschen der Metropole für den Bruchteil einer Sekunde vollkommen verstummen. Wild funkend und strauchelnd wich der Koloss zurück – das Hohlspitzgeschoss hatte sein Schulterservo in ein abstraktes Kunstwerk aus zerrissenem Metall verwandelt. Krachend ging er in einer Pfütze aus brackigem Regenwasser zu Boden, wo giftige Ölfilme in regenbogenfarbenen Schlieren sein mechanisches Grabeslager umspielten.

Ohne auch nur einen flüchtigen Blick über die Schulter zu vergeuden, stieg der Detektiv über den zuckenden Leib hinweg und teilte den schweren Perlenvorhang einer Spelunke, die den Namen 'Der flackernde Lotos' trug. Drinnen schlug ihm sogleich eine massive Wand aus betäubendem, zuckersüßem Kunstweihrauch entgegen. Hinter dem schimmernden Tresen wischte ein Barkeeper – gesegnet mit weitaus mehr Armen, als die Natur jemals vorgesehen hatte – ziellos die Flächen sauber.

"Ich muss zu Jax", verlangte er, seine Stimme nicht mehr als ein ausgedorrtes Rascheln.

Die unzähligen, insektoiden Augen des Wirts blinzelten synchron, während das Gehirn dahinter in Bruchteilen von Sekunden die Wahrscheinlichkeit des eigenen Todes abwog. "Jax empfängt niemanden", tönte es als unheimlicher, mehrstimmiger Chor zurück.

Ohne eine weitere Silbe der Verhandlung preiszugeben, legte der Detektiv eine massige Münze aus reinstem, unbeflecktem Kupfer auf das Holz. Es handelte sich um ein Relikt der alten Erde, ein Stück verflossener Geschichte, dessen schierer Wert die kühnsten Träume der Slumbewohner in den Schatten stellte.

"Sag ihm, dass der Wind sich dreht", raunte der Detektiv düster.

Gierig und lautlos verschlang ein unsichtbarer Schlitz im Tresen das wertvolle Stück. "Die Tür im Hinterzimmer", zischte das Wesen gehorsam."""
  ),
  TestCase(
    "2. Magical Realism (ES -> EN) [Long sentences, Poetic]",
    """La aldea dormía bajo un manto de estrellas que latían con el ritmo pausado de un corazón antiguo, ajena al presagio funesto que traía el viento del norte. Fue en esa madrugada de silencios espesos cuando el abuelo Aureliano, con los ojos ciegos pero la visión intacta, pronunció la profecía que condenaría a nuestra estirpe. Habló de lluvias de ceniza, de espejos rotos y de un reloj de arena que ya no medía el tiempo, sino la ausencia.
    
Nadie le creyó. Las mujeres continuaron moliendo maíz, los hombres afilando sus machetes, y los niños persiguiendo luciérnagas en el fango. Sin embargo, antes de que el sol despuntara, el río amaneció teñido de un rojo denso y metálico.""",
    """The village slumbered beneath a blanket of pulsating stars. They beat in time with an ancient heart, oblivious to the grim omen carried by the north wind. It was during that thick, silent dawn that grandfather Aureliano spoke. Though his eyes were blind, his inner vision remained sharp. He uttered the prophecy that would doom our bloodline, warning of ash rain and shattered mirrors. He spoke of an hourglass that measured absence rather than time.

His words fell on deaf ears. The women kept grinding corn. The men continued sharpening their machetes, while children chased fireflies in the mud. But the warning was real. Before the sun could even rise, the river turned a thick, metallic crimson."""
  ),
  TestCase(
    "3. Medical/Legal (DE -> FR) [Formal, Omissions]",
    """Gemäß § 4 Abs. 3 des Heilmittelwerbegesetzes (HWG) ist jegliche irreführende Werbung für Medizinprodukte strikt untersagt. Zuwiderhandlungen werden mit Geldbußen von bis zu 50.000 Euro geahndet, unbeschadet etwaiger strafrechtlicher Konsequenzen. Der Hersteller ist verpflichtet, klinische Evidenz gemäß den Vorgaben der Verordnung (EU) 2017/745 (MDR) lückenlos zu dokumentieren.

[Besondere Bestimmung für den deutschen Markt: Die Meldung von Vorkommnissen muss binnen 15 Tagen an das Bundesinstitut für Arzneimittel und Medizinprodukte (BfArM) erfolgen. Bei Todesfällen verkürzt sich die Frist auf 2 Tage.]

Eine unabhängige Zertifizierungsstelle (Benannte Stelle) muss das Qualitätsmanagementsystem jährlich auditieren.""",
    """Conformément à l'article 4, paragraphe 3, de la loi sur la publicité pour les produits de santé, toute publicité trompeuse pour les dispositifs médicaux est strictement interdite. Les infractions sont passibles de lourdes amendes, sans préjudice d'éventuelles poursuites pénales. Le fabricant a l'obligation de documenter rigoureusement les preuves cliniques, conformément aux exigences du règlement (UE) 2017/745 (RDM).

Un organisme de certification indépendant (organisme notifié) doit auditer le système de gestion de la qualité chaque année."""
  ),
  TestCase(
    "4. Slang/Subtitles (FR -> DE) [Idioms, Restructuring]",
    """Eh ben dis donc, il fait un froid de canard ce matin ! J'ai failli me geler les miches en attendant le bus.
En plus, ce con de chauffeur a failli me passer sous le nez. Si je l'avais raté, mon boss m'aurait passé un savon monumentale. 
T'sais quoi ? J'en ai ras le bol de ce taf. Je vais finir par péter un plomb et tout plaquer. On se tire aux Bahamas ?""",
    """Alter Schwede, ist das eine Hundekälte heute Morgen! Ich hab mir an der Haltestelle fast den Arsch abgefroren.
Und dann wäre mir dieser Vollidiot von Busfahrer auch noch fast vor der Nase weggefahren! Wenn ich den verpasst hätte, hätte mir mein Chef so richtig den Kopf abgerissen. 
Weißt du was? Ich hab die Schnauze gestrichen voll von diesem Job. Irgendwann ticke ich nochmal komplett aus und schmeiß einfach alles hin. Lass uns auf die Bahamas abhauen!"""
  ),
  TestCase(
    "5. Academic to Layperson (EN -> DE) [Simplification, 1:N / N:1]",
    """The objective of this longitudinal study was to evaluate the long-term efficacy and tolerability of the pharmacological intervention in cohorts exhibiting chronic neuropathic pain. Preliminary data indicates a statistically significant reduction in pain scale metrics (p < 0.01) alongside a substantial decrease in inflammatory biomarkers over a 24-month observation period. Furthermore, the incidence of adverse physiological reactions was negligible, thereby confirming the drug's safety profile.

Methodologically, the double-blind, placebo-controlled paradigm ensures the robustness of the empirical findings. Future research vectors should prioritize investigating the synergistic effects when administered concurrently with physical therapy protocols.""",
    """Das Ziel dieser Studie war es herauszufinden, ob das neue Medikament bei chronischen Nervenschmerzen langfristig hilft und gut vertragen wird. Die Ergebnisse sind sehr positiv. Die Patienten hatten deutlich weniger Schmerzen. Außerdem gingen die Entzündungen im Körper stark zurück. Das alles wurde über einen Zeitraum von zwei Jahren beobachtet. Nebenwirkungen traten so gut wie gar nicht auf. Das beweist, dass das Medikament sehr sicher ist.

Die Untersuchung wurde sehr streng und fair durchgeführt, sodass man sich auf die Ergebnisse verlassen kann. In Zukunft soll noch erforscht werden, ob das Medikament noch besser wirkt, wenn die Patienten gleichzeitig Physiotherapie machen."""
  ),
  TestCase(
    "6. Poetry / Lyrics (EN -> ES) [Rhyme, Extreme Mismatch]",
    """In the dead of the night, when the shadows grow tall,
I hear the faint whisper, the ghost in the hall.
A flicker of light, a shiver of cold,
A story of sorrow, eternally told.

Don't look in the mirror, don't open the door,
The specters are waiting to settle the score.
For debts that were buried beneath the cold stone,
Will rise from the darkness to claim what they own.""",
    """Cuando cae la noche y se alarga la sombra,
escucho el susurro, el fantasma que nombra.
Una luz que parpadea, un frío que me hiela,
una historia de tristeza que el tiempo revela.

No mires al cristal, no abras la entrada,
los muertos esperan la deuda saldada.
Pues culpas ocultas bajo la fría piedra,
saldrán de lo oscuro trepando cual hiedra."""
  ),
  TestCase(
    "7. The Great Gap (EN -> DE) [Massive Omission / Sliding Window Test]",
    "The history of the small town of Oakhaven is deeply intertwined with the ancient forest that surrounds it. Founded in 1842 by a group of pioneers, the town quickly grew into a bustling logging hub. The early settlers faced harsh winters and frequent encounters with local wildlife.\n\n" + 
    List.generate(50, (i) => "This is omitted paragraph $i. It contains some unique filler text to ensure the sentences are distinct and the algorithm processes them properly. We can add a few more sentences here to simulate a real paragraph. The quick brown fox jumps over the lazy dog. A journey of a thousand miles begins with a single step. The algorithm must slide its window past this paragraph.").join("\n\n") + 
    "\n\nIn conclusion, Oakhaven's journey from a rugged pioneer settlement to a thriving modern community is truly remarkable. Visitors are always welcome to explore its rich history and natural beauty.",
    """Die Geschichte der kleinen Stadt Oakhaven ist eng mit dem uralten Wald verbunden, der sie umgibt. Gegründet im Jahr 1842 von einer Gruppe Pioniere, wuchs die Stadt schnell zu einem belebten Holzfällerzentrum heran. Die frühen Siedler sahen sich strengen Wintern und häufigen Begegnungen mit der lokalen Tierwelt ausgesetzt.

Zusammenfassend lässt sich sagen, dass die Reise von Oakhaven von einer rauen Pioniersiedlung zu einer blühenden modernen Gemeinschaft wirklich bemerkenswert ist. Besucher sind jederzeit herzlich willkommen, ihre reiche Geschichte und natürliche Schönheit zu erkunden."""
  ),
];
