let canvas = document.getElementById("canvas");
let ctx = canvas.getContext("2d");
ctx.webkitImageSmoothingEnabled = false;
let hslToHex = (h, s, l) => {
  h /= 50;
  s /= 100;
  l /= 100;
  let r, g, b;
  if (s === 0) {
     r = g = b = l; // achromatic
  } else {
     const hue2rgb = (p, q, t) => {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
     };
     const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
     const p = 2 * l - q;
     r = hue2rgb(p, q, h + 1 / 3);
     g = hue2rgb(p, q, h);
     b = hue2rgb(p, q, h - 1 / 3);
  }
  const toHex = x => {
     const hex = Math.round(x * 255).toString(16);
     return hex.length === 1 ? '0' + hex : hex;
  };
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
};
let render = async () => {
  for (let x=0; x!=40; x++) {
     for (let y=0; y!=40; y++) {
        let real = (x - 20.0) / 10.0; // we devide x by 400 so we have a value from 0 to 1;
        let realConst = real; // we also here set a vairable that doesnt change for this pixel;
        let imaginary = (y - 20.0) / 10.0;
        let imaginaryConst = imaginary;
        let itterations = 0; // this is just the counter for how many itterations;
        while((real^2)+(imaginary^2) <= 4 && (itterations <= 50)) { // this is the loop that counts the itterations, I was first told that I should compare to 1 but a larger number like 360 works better;
           let realTemp = real;
           real = (real*real) - (imaginary*imaginary) + realConst; // here we itterate real;
           imaginary = (2*realTemp*imaginary) + imaginaryConst; // and itterate imaginary;
           ++itterations; // here we have the itteration counter increse

           //k=(real^2)+(imaginary^2); // here we redefine k using the new real and imaginary values.
        }
        if (itterations >= 50) { // 360 is our largest number of itterations;
           ctx.fillStyle = "#000000";
           ctx.fillRect(x,y,1,1); // because we did more that 360 itterations we set the pixel to black;
        }
        else { // now the loop is over this makes sure that its not the 360th itterations;
           ctx.fillStyle = hslToHex(itterations ,100,50); // this uses a hsl color code to hex code converter to get a valid hex code, this would be easy to change to accept a number higher that 360.
           ctx.fillRect(x,y,1,1); 
        }
     }
  }
  console.log("completed rendering");
};
render();
