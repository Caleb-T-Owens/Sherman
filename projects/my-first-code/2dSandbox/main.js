let canvas = document.getElementById("canvas");
let ctx = canvas.getContext("2d");
ctx.webkitImageSmoothingEnabled = false;

// Id like to have classes for each trpe of block, for now Id like to have four blocks, probs grass, dirt, stone, and air. I think haveing a specific block for air will make making a world rendering routine easier.

// Id like to store the blocks by ID and when they get loaded instances of the blocks will be created.

// For the player entity id like to make it a class that normally does not have listeners built in but functions that can have have listeners attatched or that can be called by another system to allow for easy multiplayer expansion.

// I wonder if I could do a sort of peer to peer type of multiplayer that would try to reduce the ammount of load on a server as much as possible by using other users computers to process stuff. This could make making modified clients easier so what I think would be worth trying is a system where the other clients check for strange behavior of other players and if they do detect something they would alert the serfver and hte server would start checking that players actions and potentilly terminate their connection. I couldnt let other players clients completely moderate others because one could make a client that terminates all the surrounding players movements. This would enable somone to make a client that falsely reports someone but the server could always check out for that. The things that id want the players to share amoung themselves is the world, player movements, and player actions. uploading completely different world data would be possible so there would need to be some sort of protection for that.

// I dont think I should worry about multiplayer for now because I dont yet have any real work on it done and it would require quite a complex setup.
/*let world = [
  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
  [0,0,0,0,3,0,0,0,0,0,0,0,0,0,5,0,0,0,0,0],
  [0,0,0,3,2,3,0,0,0,0,0,0,0,5,4,5,0,0,0,0],
  [0,0,3,2,1,2,3,3,0,0,0,0,0,0,4,0,0,0,0,0],
  [0,0,2,1,1,1,2,2,3,3,3,0,0,0,4,0,0,0,0,0],
  [3,3,1,1,1,1,1,1,2,2,2,3,3,3,3,3,3,3,3,3],
  [2,2,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2],
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
];*/
const randomInt = (min, max) => {
  return Math.floor(Math.random() * (+ max - +min) + min);
};

const worldLength = 1000;
let world = [
  new Array(worldLength).fill(0),
  new Array(worldLength).fill(0),
  new Array(worldLength).fill(0),
  new Array(worldLength).fill(0),
  new Array(worldLength).fill(0),
  new Array(worldLength).fill(0),
  new Array(worldLength).fill(0),
  new Array(worldLength).fill(0),
  new Array(worldLength).fill(0),
  new Array(worldLength).fill(0)
];
let oldHeight = 1;
for (let i=0;i!=worldLength;++i) {
  const heightConst = randomInt(0,3);
  // we need to count down from 9.
  let height = 9 - Math.ceil((heightConst+oldHeight)/2);
  for(height;height!=10;++height) {
    world[height][i] = 1;
  }
  height = 9 - Math.ceil((heightConst*oldHeight)/2);
  world[height - 1][i] = 2;
  world[height - 2][i] = 3;
  if (randomInt(0,12) == 1) {
    world[height - 3][i] = 4;
    world[height - 4][i] = 4;
    world[height - 5][i] = 4;
    world[height - 5][i - 1] = 5;
    world[height - 5][i + 1] = 5;
    world[height - 6][i] = 5;
  }


  oldHeight = heightConst;
};

let cameraOffset = 0;
let cameraPosition = 5;


const drawBlock = (x, y, center, edge, patternID) => {
  const pattern = [
    [
      [1,1,1,1],
      [1,0,0,1],
      [1,0,0,1],
      [1,1,1,1]
    ],
    [
      [1,0,1,0],
      [0,1,0,1],
      [1,0,1,0],
      [0,1,0,1]
    ],
    [
      [1,1,0,0],
      [0,0,1,1],
      [1,1,0,0],
      [0,0,1,1]
    ],
  ];
  let thisx=0, thisy=0;
  pattern[patternID].forEach(row => {
    row.forEach(pixel => {
      if (pixel == 1) {
        ctx.fillStyle = edge;
        ctx.fillRect((x * 16) + thisx*4 + cameraOffset - 16, (y * 16) + thisy*4, 4, 4);
        
      } else {
        ctx.fillStyle = center;
        ctx.fillRect((x * 16) + thisx*4 + cameraOffset - 16, (y * 16) + thisy*4, 4, 4);
      }
      ++thisy;
    });
    thisy=0;
    ++thisx;
  });
};

const render = () => {
  for(x=0;x!=12;++x){
    for(y=0;y!=10;++y){
      const block = world[y][x + cameraPosition - 1];
      if (block == 0){ //air
        drawBlock(x, y, "#62bbde", "#62bbde", 1);
      } else
      if (block == 1){ //stone
        drawBlock(x, y, "#9c9c9c", "#858585", 0);
      } else
      if (block == 2){ //dirt
        drawBlock(x, y, "#a36d4b", "#6e4932", 0);
      } else
      if (block == 3){ //grass
        drawBlock(x, y, "#549443", "#3f6e32", 0);
      } else
      if (block == 4){ //wood
        drawBlock(x, y, "#a1793a", "#7a5c2c", 2);
      } else
      if (block == 5){ //leaves
        drawBlock(x, y, "#3d8f31", "#2b6323", 2);
      }
    }
  }
};

const moveRight = () => {
  if (cameraOffset != -15) {
    --cameraOffset;
  } else {
    cameraOffset = 0;
    ++cameraPosition;
  }
};

const moveLeft = () => {
  if (cameraOffset != 15) {
    ++cameraOffset;
  } else {
    cameraOffset = 0;
    --cameraPosition;
  }
}; 


let aPressed = false;
let dPressed = false;
let wPressed = false;
window.addEventListener("keydown", event => {
  if (event.key == "a") {
    aPressed = true;
  } else
  if (event.key == "d") {
    dPressed = true;
  }
  if (event.key == "w") {
    wPressed = true;
  }
});
window.addEventListener("keyup", event => {
  if (event.key == "a") {
    aPressed = false;
  } else
  if (event.key == "d") {
    dPressed = false;
  }
  if (event.key == "w") {
    wPressed = false;
  }
});


let slimeHeight = 4;
let slimeOffset = 0;

const slimeMoveUp = () => {
  if (slimeOffset != -15) {
    --slimeOffset;
  } else {
    slimeOffset = 0;
    --slimeHeight;
  }
};

const slimeMoveDown = () => {
  if (slimeOffset != 15) {
    ++slimeOffset;
  } else {
    slimeOffset = 0;
    ++slimeHeight;
  }
}; 


const renderSlime = () => {
  const pattern = [
    [0,0,0,0],
    [0,1,1,0],
    [1,1,1,1],
    [1,1,1,1],
  ];
  let thisx = 0, thisy = 0;
  pattern.forEach(row => {
    row.forEach(pixel => {
      if (pixel == 1) {
        ctx.fillStyle = "#ffffff";
        ctx.fillRect((4 * 16) + thisx*4 + 8, (slimeHeight * 16) + thisy*4 + slimeOffset, 4, 4);
      }
      ++thisx;
    });
    thisx=0;
    ++thisy;
  });
};


const loop = () => {
  if (aPressed) {
    moveLeft();
  } else
  if (dPressed) {
    moveRight();
  }
  if (wPressed) {
    slimeMoveUp();
  }
  if (!wPressed && ((world[slimeHeight+1][cameraPosition + 5] == 0 && world[slimeHeight+1][cameraPosition+4] == 0) || (slimeOffset != 0))) {
    slimeMoveDown();
  }
  render();
  renderSlime();
};
setInterval(loop, 10);
//file:///Users/cath/Documents/caleb/2dSandbox/index.html