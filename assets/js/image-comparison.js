(function () {
  "use strict";

  function initializeComparisons() {
    document.querySelectorAll(".image-comparison").forEach(function (comparison) {
      if (comparison.dataset.comparisonReady === "true") return;

      var frame = comparison.querySelector(".image-comparison__frame");
      var control = comparison.querySelector(".image-comparison__control");
      if (!frame || !control) return;

      comparison.dataset.comparisonReady = "true";

      function setPosition(position) {
        var value = Math.min(100, Math.max(0, Math.round(position)));
        comparison.style.setProperty("--comparison-position", value + "%");
        control.setAttribute("aria-valuenow", value);
      }

      function setPositionFromPointer(event) {
        var bounds = frame.getBoundingClientRect();
        setPosition(((event.clientX - bounds.left) / bounds.width) * 100);
      }

      control.addEventListener("pointerdown", function (event) {
        control.setPointerCapture(event.pointerId);
        setPositionFromPointer(event);
      });

      control.addEventListener("pointermove", function (event) {
        if (control.hasPointerCapture(event.pointerId)) setPositionFromPointer(event);
      });

      control.addEventListener("keydown", function (event) {
        var current = Number(control.getAttribute("aria-valuenow"));
        var next = current;

        if (event.key === "ArrowLeft" || event.key === "ArrowDown") next -= 2;
        else if (event.key === "ArrowRight" || event.key === "ArrowUp") next += 2;
        else if (event.key === "Home") next = 0;
        else if (event.key === "End") next = 100;
        else return;

        event.preventDefault();
        setPosition(next);
      });
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeComparisons);
  } else {
    initializeComparisons();
  }
})();
