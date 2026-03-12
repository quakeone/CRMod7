// Navigation scroll effect
const nav = document.getElementById('nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 40);
});

// Mobile menu toggle
const navToggle = document.getElementById('navToggle');
const navMobile = document.getElementById('navMobile');

navToggle.addEventListener('click', () => {
  navMobile.classList.toggle('open');
});

// Close mobile menu on link click
navMobile.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', () => {
    navMobile.classList.remove('open');
  });
});

// Auto-open collapsed reference sections when navigated by hash
const revealHashTarget = () => {
  if (!window.location.hash) {
    return;
  }

  const target = document.querySelector(window.location.hash);

  if (!target) {
    return;
  }

  const panel = target.matches('.reference-panel')
    ? target
    : target.querySelector('.reference-panel');

  if (panel) {
    panel.open = true;
  }
};

window.addEventListener('hashchange', revealHashTarget);
revealHashTarget();

// Live server status indicators
const serverCards = document.querySelectorAll('.server-card[data-server-address][data-server-port]');
const serverStatusUrl = 'https://servers.quakeone.com/api/servers/status';
const serverStatusLabels = {
  0: 'Live',
  1: 'Not responding',
  2: 'Server not found',
  3: 'Query error'
};

const setServerCardState = (card, stateClass, label) => {
  const light = card.querySelector('.server-status');
  const statusText = card.querySelector('.server-state');

  if (!light || !statusText) {
    return;
  }

  light.classList.remove('status-live', 'status-down', 'status-error');
  statusText.classList.remove('state-live', 'state-down');

  if (stateClass) {
    light.classList.add(stateClass);
  }

  if (stateClass === 'status-live') {
    statusText.classList.add('state-live');
  } else if (stateClass === 'status-down') {
    statusText.classList.add('state-down');
  }

  statusText.textContent = label;
  light.setAttribute('aria-label', label);
  card.setAttribute('data-server-state', label.toLowerCase().replace(/\s+/g, '-'));
};

const updateServerStatus = async () => {
  if (!serverCards.length) {
    return;
  }

  let timeoutId;

  try {
    const controller = new AbortController();
    timeoutId = window.setTimeout(() => controller.abort(), 5000);
    const response = await fetch(serverStatusUrl, {
      cache: 'no-store',
      mode: 'cors',
      signal: controller.signal
    });

    if (!response.ok) {
      throw new Error(`Status feed returned ${response.status}`);
    }

    const servers = await response.json();

    if (!Array.isArray(servers)) {
      throw new Error('Status feed returned an unexpected payload.');
    }

    const serverMap = new Map(
      servers.map((server) => [
        `${String(server.address).toLowerCase()}:${String(server.port)}`,
        server
      ])
    );

    serverCards.forEach((card) => {
      const key = `${card.dataset.serverAddress.toLowerCase()}:${card.dataset.serverPort}`;
      const match = serverMap.get(key);

      if (!match) {
        setServerCardState(card, 'status-error', 'Status unavailable');
        return;
      }

      const currentStatus = Number(match.currentStatus);
      const label = serverStatusLabels[currentStatus] || 'Status unavailable';

      if (currentStatus === 0) {
        setServerCardState(card, 'status-live', label);
      } else {
        setServerCardState(card, 'status-down', label);
      }
    });
  } catch (error) {
    serverCards.forEach((card) => {
      setServerCardState(card, 'status-error', 'Feed unavailable');
    });
    console.warn('Unable to load QuakeOne server status feed.', error);
  } finally {
    window.clearTimeout(timeoutId);
  }
};

if (serverCards.length) {
  updateServerStatus();

  window.setInterval(() => {
    if (document.visibilityState === 'visible') {
      updateServerStatus();
    }
  }, 15000);
}

// Stats console tabs
const statsTabs = document.querySelectorAll('.stats-tab');
const statsPanels = document.querySelectorAll('.stats-panel');

statsTabs.forEach(tab => {
  tab.addEventListener('click', () => {
    statsTabs.forEach(t => t.classList.remove('active'));
    statsPanels.forEach(p => p.classList.remove('active'));
    tab.classList.add('active');
    document.getElementById('panel-' + tab.dataset.panel).classList.add('active');
  });
});

// Command filter tabs
const cmdTabs = document.querySelectorAll('.cmd-tab');
const cmdRows = document.querySelectorAll('.cmd-row');

cmdTabs.forEach(tab => {
  tab.addEventListener('click', () => {
    cmdTabs.forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    const filter = tab.dataset.filter;

    cmdRows.forEach(row => {
      if (filter === 'all' || row.dataset.cat === filter) {
        row.classList.remove('cmd-hidden');
      } else {
        row.classList.add('cmd-hidden');
      }
    });
  });
});

// Scroll-triggered animations
const animTargets = document.querySelectorAll(
  '.mode-card, .download-card, .feature-card, .integration-card, .admin-card, .comp-block, .cfg-card, .server-card, .play-link'
);

const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry, i) => {
      if (entry.isIntersecting) {
        // Stagger delay based on position within its grid
        const parent = entry.target.parentElement;
        const siblings = Array.from(parent.children);
        const index = siblings.indexOf(entry.target);
        entry.target.style.transitionDelay = `${index * 60}ms`;
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.1, rootMargin: '0px 0px -40px 0px' }
);

animTargets.forEach(el => observer.observe(el));
