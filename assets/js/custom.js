/* 代码块换行且行号对齐（配合 assets/css/jekyll-theme-chirpy.scss 的 .wrapped 规则）
 *
 * 背景：rouge/Chirpy 把行号与代码渲染成左右两个独立 <pre>，仅靠相同行高对齐；
 * 代码一旦折行，行高立即错开。这里把两列各自拆成「每行一个 span」，
 * 再用 JS 令行号 span 高度 = 代码 span 高度，折行后行号依旧逐行对应。
 *
 * 复制按钮（ClipboardJS）取的是 td.rouge-code 的文本，行号在 td.rouge-gutter 里，不受影响。
 * 无 JS 环境不执行，页面保持主题默认的横向滚动行为（渐进增强）。
 */
(function () {
  'use strict';

  /* 把高亮后的 codePre 按换行拆成多个行内容器，保留 token 的 span 结构（含跨行 token） */
  function splitCodeLines(pre) {
    var lines = [];
    var stack = [];
    var cur = document.createElement('span');

    function newLine() {
      lines.push(cur);
      stack = [];
      cur = document.createElement('span');
    }
    function target() {
      return stack.length ? stack[stack.length - 1] : cur;
    }
    function walk(node) {
      if (node.nodeType === Node.TEXT_NODE) {
        var parts = node.data.split('\n');
        for (var i = 0; i < parts.length; i++) {
          if (i) newLine();
          if (parts[i]) target().appendChild(document.createTextNode(parts[i]));
        }
      } else if (node.nodeType === Node.ELEMENT_NODE) {
        if (node.textContent.indexOf('\n') === -1) {
          target().appendChild(node.cloneNode(true));
          return;
        }
        var clone = node.cloneNode(false);
        target().appendChild(clone);
        stack.push(clone);
        for (var c = 0; c < node.childNodes.length; c++) walk(node.childNodes[c]);
        if (stack[stack.length - 1] === clone) stack.pop();
      }
    }

    for (var i = 0; i < pre.childNodes.length; i++) walk(pre.childNodes[i]);
    lines.push(cur);
    /* 结尾换行会多出一个空行容器，去掉 */
    if (lines.length > 1 && lines[lines.length - 1].textContent === '') lines.pop();
    return lines;
  }

  function restructure(highlight) {
    if (highlight.classList.contains('wrapped')) return;
    var table = highlight.querySelector('table.rouge-table');
    var gutterPre = table && table.querySelector('td.rouge-gutter pre');
    var codePre = table && table.querySelector('td.rouge-code pre');
    if (!table || !gutterPre || !codePre) return;

    var codeLines = splitCodeLines(codePre);
    var nums = gutterPre.textContent
      .split('\n')
      .map(function (s) { return s.trim(); })
      .filter(function (s) { return s !== ''; });

    var lnWrap = document.createElement('div');
    var lcWrap = document.createElement('div');
    codeLines.forEach(function (lineEl, i) {
      var n = document.createElement('span');
      n.className = 'lineno ln-line';
      n.textContent = nums[i] || String(i + 1);
      var c = document.createElement('span');
      c.className = 'lc-line';
      while (lineEl.firstChild) c.appendChild(lineEl.firstChild);
      lnWrap.appendChild(n);
      lcWrap.appendChild(c);
    });

    gutterPre.replaceWith(lnWrap);
    codePre.replaceWith(lcWrap);
    highlight.classList.add('wrapped');

    /* 行号行高逐行跟随代码行高，折行后仍对齐 */
    function sync() {
      var ns = lnWrap.children;
      var cs = lcWrap.children;
      for (var i = 0; i < cs.length; i++) {
        if (ns[i]) ns[i].style.height = cs[i].offsetHeight + 'px';
      }
    }
    sync();
    if ('ResizeObserver' in window) new ResizeObserver(sync).observe(lcWrap);
    window.addEventListener('resize', sync);
  }

  document.querySelectorAll('.highlight').forEach(restructure);
})();
