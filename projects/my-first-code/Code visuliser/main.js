let canvas = document.getElementById("canvas");
let ctx = canvas.getContext("2d");
let canvasWidth = canvas.width;
let canvasHeight = canvas.height;
ctx.fillStyle = "#ffffff";
ctx.fillRect(0,0,canvasWidth,canvasHeight);

class InputClass {
  /**
   * 
   * @param {String} name 
   * @param {Boolean} isMain 
   * @param {Array<String>} requires 
   */
  constructor (name, isMain, requires) {
    this.name = name;
    this.isMain = isMain;
    this.requires = requires;
  }
}

// I need to start with the main class and work through all the ones that it requires

// If it already has that class displayed it doesnt need to redraw it, it just needs to draw an arrow
// Im going to use coordinates to map the classes to space but it wont be the same space as the canvas, we will need to scale it to the canvas

class Helper {
  /**
   * Maps a value to a range
   * @param {Number} value 
   * @param {Number} istart 
   * @param {Number} iend 
   * @param {Number} ostart 
   * @param {Number} oend 
   */
  static map (value, istart, iend, ostart, oend) {
    return ostart + (oend - ostart) * ((value - istart) * (istart, iend));
  }
}

class Coordinate {
  /**
   * 
   * @param {Number} x 
   * @param {Number} y 
   */
  constructor (x,y) {
    this.x = x;
    this.y = y;
  }
}

class Arrow {
  /**
   * 
   * @param {Coordinate} spaceCoordinatesStart 
   * @param {Coordinate} spaceCoordinatesEnd 
   */
  constructor (spaceCoordinatesStart, spaceCoordinatesEnd) {
    this.spaceCoordinatesStart = spaceCoordinatesStart;
    this.spaceCoordinatesEnd = spaceCoordinatesEnd;
  }
}

class DisplayClass { // we will make these from a function not in the initial list
  /**
   * 
   * @param {Coordinate} coords 
   * @param {String} name 
   */
  constructor (coords, name) {
    this.coords = coords;
    this.name = name;
    this.requires = [];
    this.arrowArray = [];
  }

  /**
   * Sets the requires property
   * @param {Array<DisplayClass>} requirements 
   */
  setRequirements (requirements) { // Todo: change requirements to a more appropreate name. Eg: Users, Children, ect...
    this.requires = requirements;
  }

  /**
   * Creates the array of arrows
   */
  formArrowArray () {
    let arrowArray = [];
    this.requires.forEach(displayClass => {
      arrowArray.push(new Arrow(displayClass.coords, this.coords));
    });
    this.arrowArray = arrowArray;
  }
}

class CodeRenderer {
  /**
   * 
   * @param {Array<InputClass>} inputArray
   * @param {CanvasRenderingContext2D} ctx
   */
  constructor (inputArray, ctx) {
    this.inputArray = inputArray;
    this.ctx = ctx;
    this.canvas = ctx.getCanvas;
    this.canvasWidth = canvas.width;
    this.canvasHeight = canvas.height;
  }
  
  createTree () {
    let mainClasses = this.inputArray.filter(inputClass => {
      return inputClass.isMain; // we need to only get the main class so we use this callback function that returns isMain because .filter keeps the element if true or false if we dont want it
    }); // there should only be one so if there is more than one we will warn in the console and then procede to only consider the first element

    if (mainClasses.length < 1) {
      throw new Error("No main elements found");
    }
    if (mainClasses.length > 1) {
      console.warn("Found more that one main class. Using first class in main class list")
    }

    /**
     * 
     * @param {String} name 
     */
    let getInputArrayWithNameOf = (name) => {
      let inputClassesWithTheSameName = this.inputArray.filter(inputClass => {
        if (inputClass.name == name) {
          return true;
        } else {
          return false;
        }
      });
      if (inputClassesWithTheSameName < 1) {
        throw new Error("No input elements had the same input name, this is considered an error");
      }
      if (inputClassesWithTheSameName > 1) {
        console.warn("Found more than one input element with the same name. Using the first input class in the list");
      }
    }

    layers.push([new DisplayClass(new Coordinate(0,0), mainClasses[0].name)]);
    let children = [];
    layers[0][0].setRequirements(mainClasses[0].requires.forEach(inputClassName => {
      children.push(getInputArrayWithNameOf(inputClassName));
    })); // This was some icky code but I need to prepare the first layer 

    let layers = [];
    let madeClasses = [];
    let layerCount = 0;

    /**
     * 
     * @param {String} name 
     * @param {Number} currentLayer 
     */
    let checkIfDisplayClassIsAlreadyMade = (name, currentLayer) => {
      let foundLayer = false
      for (let i = 0; i != currentLayer; ++i) {
        layers[i].forEach(displayClass => {
          if (displayClass.name == name) {foundLayer = true;};
        });
      }
      return foundLayer;
    };


    let buildLayers = () => {
      
    }

  
  }
  
}

let testData = [
  new InputClass("Main", true, ["Helper", "Renderer"]),
  new InputClass("Helper", false, ["JsonManager"]),
  new InputClass("JsonManager", false, []),
  new InputClass("Renderer", false, ["Helper", "Entity"]),
  new InputClass("Entity", false, [])
];


let codeRenderer = new CodeRenderer(testData, ctx);
codeRenderer.createTree();