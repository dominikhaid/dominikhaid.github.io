window.addEventListener('DOMContentLoaded', (event) => {
  let url = document.location.pathname
    .replace('/docs/', '')
    .replace(/\/$/, '')
    .split('/');

  if (!url || typeof url !== 'object' || url.length < 1) return;
  url = [...url];

  let aside = document.createElement('ASIDE');
  aside.setAttribute('id', 'category-links');
  aside.setAttribute('class', 'box-up');

  let linkUrl = '';
  let clsLst = 'p-1 p-lg-2 m-0 bg-darken';

  let base = document.createElement('A');
  base.setAttribute('href', `/`);
  base.setAttribute('class', clsLst);
  base.innerText = 'Wiki:';
  aside.appendChild(base);

  url.forEach((page) => {
    if (page === '' || page === '/') return;
    linkUrl += '/' + page;
    let tr = document.createElement('P');
    tr.innerText = ' / ';
    tr.setAttribute('class', clsLst + ' text-blue');
    aside.appendChild(tr);
    let element = document.createElement('A');
    element.setAttribute('href', `/docs${linkUrl}`);
    element.setAttribute('class', clsLst);
    element.innerText = page.substring(0, 1).toUpperCase() + page.substring(1);
    aside.appendChild(element);
  });
  let container = document.querySelector('main article div');
  if (!container || typeof container !== 'object') return;

  let children = [...container.children];
  children.forEach((element) => {
    container.removeChild(element);
  });

  children.unshift(document.createElement('HR'));
  children.unshift(aside);

  children.forEach((element) => {
    container.appendChild(element);
  });
});
