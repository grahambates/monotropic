let values = 16;
let steps = 16;
const out = new Array(values * steps).fill(0);

let range = 32;
let last, k;
for (let l = 0; l < 3; l++) {
  last = 0;
  k = 0;
  for (let i = 0; i < values; i++) {
    const v = Math.floor(Math.random() * range);
    const d = (v - last) / steps;
    for (let j = 0; j < steps; j++) {
      out[k] += Math.round(last);
      last += d;
      k++;
    }
    last = v;
  }
  values *= 2;
  steps /= 2;
  range /= 2;
}

console.log(out.join(","));
