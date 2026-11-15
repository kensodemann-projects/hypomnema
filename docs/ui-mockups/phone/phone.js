/* Hypomnema phone mock-ups: fit the device to the window, simple tabs. */
(function () {
  const embed = window.self !== window.top;
  if (embed) document.documentElement.classList.add('embed');

  function fit() {
    if (embed) return;
    const d = document.querySelector('.device');
    if (!d) return;
    const s = Math.min(1, (window.innerHeight - 40) / 912);
    d.style.transform = s < 1 ? `scale(${s})` : '';
    d.style.margin = s < 1 ? `${-(912 * (1 - s)) / 2}px ${-(432 * (1 - s)) / 2}px` : '';
  }
  window.addEventListener('resize', fit);

  document.addEventListener('DOMContentLoaded', () => {
    fit();
    document.querySelectorAll('[data-tabs]').forEach((group) => {
      const tabs = group.querySelectorAll('[data-tab]');
      tabs.forEach((t) => t.addEventListener('click', () => {
        tabs.forEach((x) => x.classList.toggle('active', x === t));
        document.querySelectorAll('[data-panel]').forEach((p) => { p.hidden = p.dataset.panel !== t.dataset.tab; });
      }));
    });
  });
})();
