import './style.css'

const canvas = document.querySelector<HTMLCanvasElement>("canvas")!;
const context = canvas.getContext("2d")!;

const width = canvas.width;
const height = canvas.height;

for (let x = 0; x != width; x++) {
  for (let y = 0; y != height; y++) {
    const [r, g, b] = getPixelColor(x, y)
    context.fillStyle = `rgb(${r}, ${g}, ${b})`
    context.fillRect(x, height - y, 1, 1);
  }
}

function getPixelColor(x: number, y: number): [number, number, number] {
  if (y == x) return [0, 0, 0];
  if (y == x / 2) return [0, 0, 0];
  if (y == x / 3) return [0, 0, 0];
  if (y == x / 4) return [0, 0, 0];
  if (y == x / 5) return [0, 0, 0];
  return [255, 255, 255]
}