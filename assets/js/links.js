window.addEventListener('DOMContentLoaded', function () {
  if (typeof anchors !== 'undefined') {
    anchors.options.visible = 'always';
    anchors.add('a[href^=http]:not(.wikilink)');
  }
});
