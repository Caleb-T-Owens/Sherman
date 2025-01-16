let canvas = document.getElementById("canvas");
let ctx = canvas.getContext("2d");
let imageList = [];
let imageCounter = 0;

// There will need to be a world grid. I dont really know how to do it
// I think it will actually be best to make the game engine first and then make the map editor so I'm going to freeze this till then

class ImageSelector {
  constructor (image, name, id) {
    this.image = image;
    this.image.className = "image";
    this.name = name;
    this.id = id;
    this.buildImage()
  }
  buildImage () {
    let container = document.createElement("div");
    container.className = "image-container";
    container.appendChild(this.image);
    container.innerHTML += this.name;
    let parent = document.getElementById("blocks");
    parent.appendChild(container);
  }
}



let onUploadPressed = () => {
  let images = document.getElementById("images");
  console.log(images.files);
  for (let uploadedImage of images.files) {
    let image = new Image();
    image.src = URL.createObjectURL(uploadedImage);
      image.onload = () => {
        imageList.push(new ImageSelector(image, uploadedImage.name, imageCounter));
        ++imageCounter;
        //ctx.drawImage(image, 0, 0, 100, 100);
        //console.log(image);
      };
    
  }
}