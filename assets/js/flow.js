var MD_EXT = [
  '.md',
  '.markdown',
  '.mdx',
  '.mdown',
  '.mkdn',
  '.mkd',
  '.mdwn',
  '.mdtxt',
  '.mdtext',
  '.text',
  '.Rmd',
];
function normalizeMdLink(link) {
  var url = new URL(link);
  var mdFileExt = MD_EXT.find((ext) => url.pathname.endsWith(ext));
  if (mdFileExt) {
    url.pathname = url.pathname.slice(0, mdFileExt.length * -1);
  }
  return Array.from(new Set(url.toString().split('/'))).join('/');
}

window.addEventListener('DOMContentLoaded', (event) => {
  document
    .querySelectorAll('.markdown-body a[title]:not([href^=http])')
    .forEach((a) => {
      // filter to only wiki-links
      var prev = a.previousSibling;
      var next = a.nextSibling;
      if (
        prev instanceof Text &&
        prev.textContent.endsWith('[') &&
        next instanceof Text &&
        next.textContent.startsWith(']')
      ) {
        // remove surrounding brackets
        prev.textContent = prev.textContent.slice(0, -1);
        next.textContent = next.textContent.slice(1);

        // add CSS list for styling
        a.classList.add('wikilink');

        // replace page-link with "Page Title"...
        a.innerText = a.title;

        // ...and normalize the links to allow html pages navigation
        a.href = normalizeMdLink(a.href);
      }
    });

  document.querySelectorAll('.github-only').forEach((el) => {
    el.remove();
  });
});
