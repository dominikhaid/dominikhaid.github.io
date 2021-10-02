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

/**
 * Create Table of Contents
 * @param {string} id defaults to toc
 * @returns void
 */
function createToc(id = 'toc') {
  let toc = document.getElementById(id);
  if (!toc || !toc.children || toc.children.length < 1) return;
  toc = [...toc.children];
  toc.forEach((li) => {
    let newArchor = document.createElement('A');
    newArchor.innerText = li.innerText;
    newArchor.setAttribute(
      'href',
      '#' + li.innerText.toLowerCase().replace(' ', '-')
    );
    li.innerText = '';
    li.appendChild(newArchor);
  });
}

/**
 * Set state of the main nav
 * @param {string} id defaults to main-nav
 * @returns void
 */
function setMainNav(id = 'main-nav') {
  let url = window.location.pathname.replace('/docs/', '').split('/');
  if (!Array.isArray(url)) return;
  url.forEach((el) => {
    if (el === '') return;
    let li = document.querySelector(`nav#${id} li#${el}`);
    if (typeof li === 'object') li.classList.add('active');
  });
}

const toggleNav = (id = 'main-nav') => {
  let nav = document.getElementById(id);
  if (!nav) return false;
  nav.classList.toggle('hidden');

  !nav.classList.contains('hidden') &&
    window.document.body.setAttribute('style', 'overflow: hidden');
  nav.classList.contains('hidden') &&
    window.document.body.setAttribute('style', '');

  return true;
};

window.addEventListener('DOMContentLoaded', (event) => {
  createToc();
  setMainNav();

  let navBtn = document.getElementById('mobile-nav');
  navBtn && navBtn.addEventListener('click', () => toggleNav());
  document.getElementById('main-nav') &&
    document.getElementById('main-nav').classList.add('hidden');

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

  if (typeof anchors !== 'undefined') {
    anchors.options.visible = 'always';
    anchors.add('a[href^=http]:not(.wikilink)');
  }
  var list = document.querySelectorAll('.list');

  function accordion(e) {
    e.stopPropagation();
    if (this.classList.contains('active')) {
      this.classList.remove('active');
    } else if (this.parentElement.parentElement.classList.contains('active')) {
      this.classList.add('active');
    } else {
      for (i = 0; i < list.length; i++) {
        list[i].classList.remove('active');
      }
      this.classList.add('active');
    }
  }
  for (i = 0; i < list.length; i++) {
    list[i].addEventListener('click', accordion);
  }
});
