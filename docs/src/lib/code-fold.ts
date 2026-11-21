// A long block on the page of a component opens folded at the number of lines
// its page gives, with a button that shows the rest. Without this script the
// block shows whole and scrolls inside, as before.
const folds = [...document.querySelectorAll<HTMLElement>('.code-fold')];

// Marked at once, so lib/code-scroll.ts leaves a folded block out of the tab order.
folds.forEach((fold) => fold.toggleAttribute('data-folded', true));

document.fonts.ready.then(() => {
  for (const fold of folds) {
    const pre = fold.querySelector<HTMLElement>('pre');
    const cut = pre?.querySelectorAll<HTMLElement>('.ec-line')[Number(fold.dataset.shown)];
    if (!pre || !cut) {
      fold.removeAttribute('data-folded');
      continue;
    }
    pre.style.maxHeight = `${cut.getBoundingClientRect().top - pre.getBoundingClientRect().top}px`;
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'code-fold-toggle';
    button.textContent = `Show all ${fold.dataset.lines} lines`;
    button.addEventListener('click', () => {
      fold.removeAttribute('data-folded');
      pre.style.maxHeight = '';
      button.remove();
      if (!pre.hasAttribute('tabindex')) pre.setAttribute('tabindex', '-1');
      pre.focus({ preventScroll: true });
    });
    fold.append(button);
  }
});
