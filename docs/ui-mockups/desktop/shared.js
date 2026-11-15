/* Hypomnema mock-ups: light/dark review switch and simple SVG charts. */
(function () {
  const KEY = 'hypomnema-mock-theme';
  const read = () => { try { return localStorage.getItem(KEY); } catch (e) { return null; } };
  const write = (t) => { try { localStorage.setItem(KEY, t); } catch (e) { /* ignore */ } };
  let theme = read() || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  const apply = (t) => { document.documentElement.dataset.theme = t; };
  apply(theme);

  window.addEventListener('message', (e) => {
    if (e.data && e.data.hmTheme) apply(e.data.hmTheme);
  });

  const syncFrames = () => document.querySelectorAll('iframe').forEach((f) => {
    try { f.contentWindow.postMessage({ hmTheme: theme }, '*'); } catch (e) { /* ignore */ }
  });

  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('iframe').forEach((f) => f.addEventListener('load', syncFrames));
    document.querySelectorAll('.radio-option, .type-card, .segmented button').forEach((el) => {
      const cls = el.matches('.segmented button') ? 'active' : 'selected';
      el.addEventListener('click', () => {
        [...el.parentElement.children].forEach((s) => s.classList.remove(cls));
        el.classList.add(cls);
      });
    });
    if (window.self !== window.top) {
      document.querySelectorAll('.snackbar').forEach((s) => s.remove());
      return;
    }
    const btn = document.createElement('button');
    btn.className = 'mock-theme-toggle';
    btn.title = 'Mock-up only: switch between light and dark themes';
    const label = () => {
      btn.innerHTML = '<span class="material-symbols-outlined">' +
        (theme === 'dark' ? 'light_mode' : 'dark_mode') + '</span>MOCK · ' +
        (theme === 'dark' ? 'Light theme' : 'Dark theme');
    };
    label();
    btn.addEventListener('click', () => {
      theme = theme === 'dark' ? 'light' : 'dark';
      write(theme);
      apply(theme);
      label();
      syncFrames();
    });
    document.body.appendChild(btn);
  });
})();

/*
 * Draws a time-based line chart into `el`.
 * points: [['2026-11-14', value], ...]
 * Options: start, end, yMin, yMax, yTicks, xTicks [[date, label]], target {value, label},
 * targetDate {date, label}, today, breakDays (connect points only when they are at most
 * this many days apart), mood (draw points as mood swatches), yFormat, height.
 */
window.hmChart = function (el, o) {
  if (!el.hmResize) {
    el.hmResize = true;
    let last = el.clientWidth;
    window.addEventListener('resize', () => {
      if (el.clientWidth !== last) { last = el.clientWidth; window.hmChart(el, el.hmOptions); }
    });
  }
  el.hmOptions = o;
  const W = o.width || el.clientWidth || 760, H = o.height || 260;
  const m = { l: o.noYAxis ? 12 : (o.mood ? 40 : 52), r: 24, t: 18, b: 30 };
  const day = 864e5;
  const t = (s) => new Date(s + 'T00:00:00').getTime();
  const x0 = t(o.start), x1 = t(o.end);
  const X = (v) => (m.l + (v - x0) / (x1 - x0) * (W - m.l - m.r)).toFixed(1);
  const Y = (v) => (m.t + (o.yMax - v) / (o.yMax - o.yMin) * (H - m.t - m.b)).toFixed(1);
  const fmt = o.yFormat || ((v) => v);
  const fixed = o.width ? ` style="width:${W}px;max-width:none"` : '';
  let s = `<svg class="chart-svg" viewBox="0 0 ${W} ${H}"${fixed} role="img" aria-label="${o.label || 'Chart'}">`;

  o.yTicks.forEach((v) => {
    s += `<line class="grid" x1="${m.l}" x2="${W - m.r}" y1="${Y(v)}" y2="${Y(v)}"/>`;
    if (o.noYAxis) return;
    if (o.mood) {
      s += `<rect x="${m.l - 30}" y="${Y(v) - 9}" width="18" height="18" rx="5" fill="var(--mood-${v})"/>` +
        `<text class="mood-pt-text" x="${m.l - 21}" y="${+Y(v) + 3.5}" text-anchor="middle">${v}</text>`;
    } else {
      s += `<text class="axis" x="${m.l - 8}" y="${+Y(v) + 4}" text-anchor="end">${fmt(v)}</text>`;
    }
  });
  (o.xTicks || []).forEach(([d, label]) => {
    s += `<text class="axis" x="${X(t(d))}" y="${H - 8}" text-anchor="middle">${label}</text>`;
  });
  if (o.target) {
    const y = Y(o.target.value);
    s += `<line class="target" x1="${m.l}" x2="${W - m.r}" y1="${y}" y2="${y}"/>` +
      `<text class="target-label" x="${m.l + 6}" y="${y - 6}">${o.target.label}</text>`;
  }
  if (o.targetDate) {
    const x = X(t(o.targetDate.date));
    s += `<line class="target" x1="${x}" x2="${x}" y1="${m.t}" y2="${H - m.b}"/>` +
      `<text class="target-label" x="${x - 6}" y="${m.t + 10}" text-anchor="end">${o.targetDate.label}</text>`;
  }
  if (o.today) {
    const x = X(t(o.today));
    s += `<line class="today" x1="${x}" x2="${x}" y1="${m.t}" y2="${H - m.b}"/>` +
      `<text class="today-label" x="${x}" y="${m.t - 6}" text-anchor="middle">Today</text>`;
  }

  let path = '', prev = null;
  o.points.forEach(([d, v]) => {
    const ts = t(d);
    const join = prev !== null && (o.breakDays == null || (ts - prev) / day <= o.breakDays);
    path += `${join ? 'L' : 'M'}${X(ts)},${Y(v)} `;
    prev = ts;
  });
  s += `<path class="series${o.mood ? ' mood-line' : ''}" d="${path}"/>`;

  o.points.forEach(([d, v]) => {
    const x = X(t(d)), y = Y(v);
    if (o.mood) {
      s += `<rect x="${x - 8}" y="${y - 8}" width="16" height="16" rx="4" fill="var(--mood-${v})" stroke="var(--surface)" stroke-width="1.5"/>` +
        `<text class="mood-pt-text" x="${x}" y="${+y + 3.5}" text-anchor="middle">${v}</text>`;
    } else {
      s += `<circle class="dot" cx="${x}" cy="${y}" r="4"><title>${d}: ${fmt(v)}</title></circle>`;
    }
  });
  s += '</svg>';
  el.innerHTML = s;
};
