// A preview stops on the still of its social card, the middle frame of the
// animation, named by the data-still attribute of its image. With Reduce
// Motion a <source> picks the still; the Pause button swaps it in by hand.

/** Marks the image as a still once the still has loaded, so the moving preview never shows scaled, nor the still bare. */
export function trackStill(image: HTMLImageElement) {
  const update = () => image.classList.toggle('still', image.currentSrc === image.dataset.still);
  image.addEventListener('load', update);
  if (image.complete) update();
}

/** Shows the still of the image while paused, and its moving preview again once played. */
export function showStill(image: HTMLImageElement, paused: boolean) {
  const still = image.dataset.still;
  if (!still) return;
  if (paused && image.src !== still) {
    image.dataset.moving = image.src;
    image.src = still;
  } else if (!paused && image.dataset.moving) {
    image.src = image.dataset.moving;
  }
}
