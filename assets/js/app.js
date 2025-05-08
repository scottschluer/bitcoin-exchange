// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { CalculateBtcAmount, CalculateUsdAmount, InputValueSetter } from "./hooks/calculator_hooks"
import PriceChartHook from "./hooks/chart_hook"

// Theme related functionality
const Theme = {
  // Check if user prefers dark mode
  userPrefersDark() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  },

  // Get theme from local storage or use system preference
  getTheme() {
    return localStorage.getItem('theme') ||
      (this.userPrefersDark() ? 'dark' : 'light');
  },

  // Set theme in local storage and apply to document
  setTheme(theme) {
    localStorage.setItem('theme', theme);

    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }
};

// Initialize theme on page load
Theme.setTheme(Theme.getTheme());

// Theme toggle hook to handle dark mode switching
let Hooks = {}
Hooks.ThemeToggle = {
  mounted() {
    // Check for saved theme preference or use OS preference
    const savedTheme = localStorage.getItem('theme')
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches

    if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }

    // Toggle theme on click
    this.el.addEventListener('click', () => {
      if (document.documentElement.classList.contains('dark')) {
        document.documentElement.classList.remove('dark')
        localStorage.setItem('theme', 'light')
      } else {
        document.documentElement.classList.add('dark')
        localStorage.setItem('theme', 'dark')
      }
    })
  }
}

// Hook for animating value changes
Hooks.AnimateValue = {
  mounted() {
    // Store the initial value to track changes
    this.lastValue = this.el.textContent.trim();

    // Add a method to apply animation classes
    this.animateChange = (newValue) => {
      if (newValue !== this.lastValue) {
        // Remove any existing animation classes first
        this.el.classList.remove('animate-increase', 'animate-decrease');

        // Force a reflow to ensure the animation triggers even if classes are the same
        void this.el.offsetWidth;

        // Compare numeric values if possible
        const numericOld = parseFloat(this.lastValue.replace(/[^0-9.-]+/g, ''));
        const numericNew = parseFloat(newValue.replace(/[^0-9.-]+/g, ''));

        if (!isNaN(numericOld) && !isNaN(numericNew)) {
          if (numericNew > numericOld) {
            this.el.classList.add('animate-increase');
          } else if (numericNew < numericOld) {
            this.el.classList.add('animate-decrease');
          }
        }

        this.lastValue = newValue;
      }
    };

    // Set up an observer to detect content changes
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'characterData' || mutation.type === 'childList') {
          const newValue = this.el.textContent.trim();
          this.animateChange(newValue);
        }
      });
    });

    // Start observing content changes
    observer.observe(this.el, {
      characterData: true,
      childList: true,
      subtree: true
    });

    // Also handle the LiveView updated event
    this.handleEvent("updated", () => {
      const newValue = this.el.textContent.trim();
      this.animateChange(newValue);
    });
  }
}

// Add calculator hooks for Bitcoin transactions
Hooks.CalculateBtcAmount = CalculateBtcAmount;
Hooks.CalculateUsdAmount = CalculateUsdAmount;
Hooks.InputValueSetter = InputValueSetter;

// Add price chart hook (placeholder for now)
Hooks.PriceChart = PriceChartHook;

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

