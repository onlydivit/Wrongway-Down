const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const read = name => JSON.parse(fs.readFileSync(path.join(root, name), 'utf8').replace(/^\uFEFF/, ''));
const write = (name, data) => fs.writeFileSync(path.join(root, name), JSON.stringify(data, null, 2) + '\n');
const manifest = read('levels/campaign.json').slice(0, 10);
const names = ['Wake Signal','Quick Step','Upper Instinct','Blink Crossing','Narrow Orbit','Double Take','Ceiling Rush','Pulse Runner','Split Focus','Reflex Check','Afterimage','Cross Current','Warning Signs','Rapid Return','Two Beats','Alien Relay','Switch Sprint','Hot Circuit','Opposite Day','Pulse Exam','Fast Orbit','Twin Signals','Pressure Line','Reverse Reflex','Short Window','Red Horizon','Chain Reaction','Last Opening','Deep Focus','Gravity Master'];
const layouts = [
 {route:[175,380,570,760],walls:[],spikes:[[240,100,1],[430,100,-1],[620,100,1],[810,100,-1]],cp:[570,-1],sw:[['A',380,1],['B',760,1]],haz:[290,680],beam:480,endBeam:930},
 {route:[180,450,680],walls:[[750,460,100,140]],spikes:[[250,125,1],[500,125,-1]],cp:[450,1],sw:[['A',410,-1],['B',680,-1]],haz:[330,800],beam:560,endBeam:930},
 {route:[180,410,610,810],walls:[[250,460,75,140],[460,160,75,140],[660,460,75,140],[860,160,75,140]],spikes:[[350,25,1],[550,25,-1],[750,25,1]],cp:[610,-1],sw:[['A',410,1],['B',610,-1]],haz:[330,710],beam:490,endBeam:930},
 {route:[165,355,555,755],walls:[[230,460,90,140],[625,460,90,140]],spikes:[[425,80,-1],[820,80,-1]],cp:[555,-1],sw:[['A',355,1],['B',755,1]],haz:[280,670],beam:480,endBeam:930},
 {route:[160,335,505,675,845],walls:[],spikes:[[220,80,1],[390,80,-1],[560,80,1],[730,80,-1],[900,70,1]],cp:[675,1],sw:[['A',335,1],['B',675,1]],haz:[260,600],beam:435,endBeam:960},
 {route:[180,400,605,810],walls:[[245,440,75,160],[450,160,75,160],[655,440,75,160],[860,160,75,140]],spikes:[[335,25,1],[545,25,-1],[745,25,1]],cp:[605,-1],sw:[['A',400,1],['B',605,-1]],haz:[290,700],beam:480,endBeam:930}
];
for (let index = 0; index < 10; index++) {
 const file = manifest[index].replace('res://', ''); const data = read(file);
 data.reward = 100 + index * 10; data.chapter = 'FOUNDATIONS'; data.pulses ??= [];
 write(file, data);
}
for (let offset = 0; offset < 30; offset++) {
 const number = offset + 11; const title = names[offset]; const id = title.toLowerCase().replaceAll(' ', '_');
 const layout = structuredClone(layouts[offset % layouts.length]);
 const shift = [0, 5, -5, 8, -8][Math.floor(offset / 6)];
 const inverted = offset % 4 === 2 || offset % 4 === 3;
 const direction = inverted ? -1 : 1;
 const exitDirection = (layout.route.length % 2 === 0 ? 1 : -1) * direction;
 const chapter = number <= 20 ? 'REFLEX' : number <= 30 ? 'PULSE' : 'MASTERY';
 const period = +(4.8 - offset * 0.075).toFixed(3);
 const safe = +(2.8 - offset * 0.045).toFixed(3);
 const warning = +(0.65 - offset * 0.005).toFixed(3);
 const active = +(1.1 + offset * 0.02).toFixed(3);
 const data = {
  id, title, chapter, reward: 100 + (number - 1) * 10,
  difficulty: `${String(number).padStart(2, '0')} / ${chapter}`,
  hint: number === 11 ? 'Pulse barriers: PASS is safe, READY warns, STOP kills. Watch the next opening.' : number <= 20 ? 'React to the patrol, then cross the pulse while it reads PASS. Stop before READY.' : number <= 30 ? 'Two pulse cycles. Watch each warning, collect both switches, and keep your landing clear.' : 'Shorter openings, faster patrols. Brake before a warning and commit to the next safe crossing.',
  spawn: [130, inverted ? 182 : 578, direction], exit: [1040, exitDirection === 1 ? 532 : 160, exitDirection],
  walls: layout.walls.map(([x,y,w,h]) => [x + shift, inverted ? 760 - y - h : y, w, h]),
  spikes: layout.spikes.map(([x,w,s]) => [x + shift, w, s * direction]),
  checkpoints: [[layout.cp[0] + shift, layout.cp[1] * direction]],
  hazards: layout.haz.slice(0, number < 15 ? 1 : 2).map((x, index) => [x + shift, 180, 580, +(period + index * 0.25).toFixed(3), +((offset * 0.13 + index * 0.31) % 1).toFixed(2), 17]),
  switches: layout.sw.slice(0, number < 18 ? 1 : 2).map(([key,x,s]) => [key, x + shift, s * direction]),
  gates: [[1005, number < 18 ? ['A'] : ['A','B']]],
  pulses: [[layout.endBeam, safe, warning, active, +((offset * 0.17) % 1).toFixed(2)]]
 };
 if (number >= 21) data.pulses.unshift([layout.beam + shift, +(safe + 0.2).toFixed(3), warning, active, +((offset * 0.11 + 0.4) % 1).toFixed(2)]);
 const file = `levels/${number}_${id}.json`; write(file, data); manifest.push(`res://${file}`);
}
write('levels/campaign.json', manifest);
console.log(`Generated ${manifest.length} campaign levels.`);
