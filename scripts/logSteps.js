// To get a constant zoom speed we need a logarithmic curve
// Create a table to look up linear values

// multiplier set by trial-and-error to get range $100-$800 over 256 steps
const mul = 1.008155
const steps = 256

let v = 256 // unit for fixed point
const values = []
for (let i=0; i<= steps; i++) {
  values.push('$' + Math.round(v).toString(16))
  v = v*mul
}
console.log(values.join(','))