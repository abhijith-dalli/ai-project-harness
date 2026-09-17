(function () {
  'use strict';

  // ── Data Store ──────────────────────────────────────────────────────────
  const data = {
    executions: [],
    events: [],
    agentRuns: [],
    agents: [],
    skills: [],
    hooks: [],
    memory: []
  };

  const filters = {
    startDate: null,
    endDate: null,
    provider: 'all',
    agent: 'all',
    status: 'all',
    eventType: 'all'
  };

  const chartInstances = {};
  let currentSection = 'overview';

  // ── JSONL Loader ────────────────────────────────────────────────────────
  async function loadJSONL(path) {
    try {
      const resp = await fetch(path);
      if (!resp.ok) return [];
      const text = await resp.text();
      if (!text.trim()) return [];
      return text.split('\n')
        .filter(line => line.trim())
        .map(line => {
          try { return JSON.parse(line); }
          catch { return null; }
        })
        .filter(Boolean);
    } catch {
      return [];
    }
  }

  // ── Markdown Frontmatter Parser ─────────────────────────────────────────
  function parseFrontmatter(text) {
    const match = text.match(/^---\n([\s\S]*?)\n---/);
    if (!match) return { body: text, meta: {} };
    const meta = {};
    match[1].split('\n').forEach(line => {
      const idx = line.indexOf(':');
      if (idx > 0) {
        const key = line.slice(0, idx).trim();
        let val = line.slice(idx + 1).trim();
        if (val === 'true') val = true;
        else if (val === 'false') val = false;
        meta[key] = val;
      }
    });
    return { body: text.slice(match[0].length).trim(), meta };
  }

  // ── Harness Definitions Loader ──────────────────────────────────────────
  async function loadHarnessDefinitions() {
    const base = '../';

    // Agents
    const agentFiles = [
      'orchestrator', 'planner', 'implementer', 'researcher',
      'debugger', 'explorer', 'reviewer'
    ];
    for (const name of agentFiles) {
      try {
        const resp = await fetch(`${base}agents/${name}.md`);
        if (resp.ok) {
          const text = await resp.text();
          const { meta } = parseFrontmatter(text);
          data.agents.push({
            name: meta.name || name,
            file: name,
            description: meta.description || '',
            mode: meta.mode || 'subagent'
          });
        }
      } catch { /* skip */ }
    }

    // Skills
    const skillDirs = [
      'brainstorming', 'codebase-exploration', 'context-management',
      'dispatching-parallel-agents', 'executing-plans', 'git-workflow',
      'memory-discipline', 'memory-recall', 'memory-save', 'planning',
      'receiving-code-review', 'requesting-code-review',
      'subagent-driven-development', 'systematic-debugging',
      'test-driven-development', 'testing', 'verifying-before-completion'
    ];
    for (const dir of skillDirs) {
      try {
        const resp = await fetch(`${base}skills/${dir}/SKILL.md`);
        if (resp.ok) {
          const text = await resp.text();
          const { meta } = parseFrontmatter(text);
          data.skills.push({
            name: meta.name || dir,
            dir,
            description: meta.description || ''
          });
        }
      } catch { /* skip */ }
    }

    // Hooks
    const hookFiles = ['session-start', 'before-task', 'after-task', 'before-commit'];
    for (const name of hookFiles) {
      try {
        const resp = await fetch(`${base}hooks/${name}.md`);
        if (resp.ok) {
          const text = await resp.text();
          const { meta } = parseFrontmatter(text);
          data.hooks.push({
            name: meta.name || name,
            file: name,
            event: meta.lifecycle_event || name,
            description: meta.purpose || ''
          });
        }
      } catch { /* skip */ }
    }

    // Memory
    const memoryDirs = ['decisions', 'lessons', 'observations', 'project'];
    for (const dir of memoryDirs) {
      try {
        const resp = await fetch(`${base}memory/shared/${dir}/`);
        if (resp.ok) {
          const text = await resp.text();
          const links = text.match(/href="[^"]+\.md"/g) || [];
          for (const link of links) {
            const file = link.match(/href="([^"]+)"/)[1];
            try {
              const mResp = await fetch(`${base}memory/shared/${dir}/${file}`);
              if (mResp.ok) {
                const mText = await mResp.text();
                const { meta } = parseFrontmatter(mText);
                data.memory.push({
                  type: dir,
                  topic: meta.topic || file.replace('.md', ''),
                  status: meta.status || 'active',
                  created: meta.created || null,
                  updated: meta.updated || null,
                  file
                });
              }
            } catch { /* skip */ }
          }
        }
      } catch { /* skip */ }
    }
  }

  // ── Data Loading ────────────────────────────────────────────────────────
  async function loadAllData() {
    const [executions, events, agentRuns] = await Promise.all([
      loadJSONL('../data/executions.jsonl'),
      loadJSONL('../data/events.jsonl'),
      loadJSONL('../data/agent_runs.jsonl')
    ]);

    data.executions = executions;
    data.events = events;
    data.agentRuns = agentRuns;

    await loadHarnessDefinitions();

    updateDataStatus();
    populateFilterOptions();
  }

  function updateDataStatus() {
    const dot = document.getElementById('statusDot');
    const text = document.getElementById('statusText');
    const hasRuntime = data.executions.length + data.events.length + data.agentRuns.length > 0;
    const hasDefs = data.agents.length + data.skills.length > 0;

    if (hasRuntime && hasDefs) {
      dot.className = 'status-dot loaded';
      text.textContent = 'All data loaded';
    } else if (hasDefs) {
      dot.className = 'status-dot partial';
      text.textContent = 'Definitions only';
    } else {
      dot.className = 'status-dot error';
      text.textContent = 'No data';
    }
  }

  // ── Filter Options ──────────────────────────────────────────────────────
  function populateFilterOptions() {
    const providers = new Set();
    const agents = new Set();
    const eventTypes = new Set();

    data.executions.forEach(e => { if (e.provider) providers.add(e.provider); });
    data.agentRuns.forEach(r => { if (r.agent) agents.add(r.agent); });
    data.events.forEach(e => { if (e.event) eventTypes.add(e.event); });
    data.agents.forEach(a => agents.add(a.name));

    const providerSelect = document.getElementById('filterProvider');
    providers.forEach(p => {
      const opt = document.createElement('option');
      opt.value = p; opt.textContent = p;
      providerSelect.appendChild(opt);
    });

    const agentSelect = document.getElementById('filterAgent');
    agents.forEach(a => {
      const opt = document.createElement('option');
      opt.value = a; opt.textContent = a;
      agentSelect.appendChild(opt);
    });

    const eventSelect = document.getElementById('filterEventType');
    eventTypes.forEach(e => {
      const opt = document.createElement('option');
      opt.value = e; opt.textContent = e;
      eventSelect.appendChild(opt);
    });
  }

  // ── Filter Application ──────────────────────────────────────────────────
  function getFilteredData() {
    let executions = [...data.executions];
    let events = [...data.events];
    let agentRuns = [...data.agentRuns];

    if (filters.startDate) {
      const start = new Date(filters.startDate);
      executions = executions.filter(e => new Date(e.started_at) >= start);
      events = events.filter(e => new Date(e.timestamp) >= start);
      agentRuns = agentRuns.filter(r => new Date(r.started_at) >= start);
    }
    if (filters.endDate) {
      const end = new Date(filters.endDate);
      end.setHours(23, 59, 59, 999);
      executions = executions.filter(e => new Date(e.started_at) <= end);
      events = events.filter(e => new Date(e.timestamp) <= end);
      agentRuns = agentRuns.filter(r => new Date(r.started_at) <= end);
    }
    if (filters.provider !== 'all') {
      executions = executions.filter(e => e.provider === filters.provider);
    }
    if (filters.agent !== 'all') {
      agentRuns = agentRuns.filter(r => r.agent === filters.agent);
      executions = executions.filter(e => {
        const runs = data.agentRuns.filter(r => r.execution_id === e.execution_id && r.agent === filters.agent);
        return runs.length > 0;
      });
    }
    if (filters.status !== 'all') {
      executions = executions.filter(e => e.status === filters.status);
    }
    if (filters.eventType !== 'all') {
      events = events.filter(e => e.event === filters.eventType);
    }

    return { executions, events, agentRuns };
  }

  // ── Metrics ─────────────────────────────────────────────────────────────
  function computeOverviewMetrics(fe) {
    const total = fe.executions.length;
    const succeeded = fe.executions.filter(e => e.status === 'success').length;
    const failed = fe.executions.filter(e => e.status === 'failed').length;
    const agentsUsed = new Set(fe.agentRuns.map(r => r.agent)).size;
    const skillsUsed = new Set(fe.events.filter(e => e.event === 'SKILL_USED').map(e => e.skill).filter(Boolean)).size;
    const memCount = data.memory.length;
    const hooksExecuted = fe.events.filter(e => e.event === 'HOOK_COMPLETED').length;

    let avgDuration = 0;
    const durations = fe.executions.filter(e => e.started_at && e.completed_at)
      .map(e => new Date(e.completed_at) - new Date(e.started_at));
    if (durations.length) avgDuration = durations.reduce((a, b) => a + b, 0) / durations.length;

    return [
      { label: 'Total Executions', value: total, icon: 'bi-play-circle', color: 'blue' },
      { label: 'Successful', value: succeeded, icon: 'bi-check-circle', color: 'green' },
      { label: 'Failed', value: failed, icon: 'bi-x-circle', color: 'red' },
      { label: 'Agents Used', value: agentsUsed, icon: 'bi-robot', color: 'purple' },
      { label: 'Skills Used', value: skillsUsed, icon: 'bi-lightning', color: 'yellow' },
      { label: 'Memory Records', value: memCount, icon: 'bi-database', color: 'cyan' },
      { label: 'Hooks Executed', value: hooksExecuted, icon: 'bi-lightning-fill', color: 'blue' },
      { label: 'Avg Duration', value: formatDuration(avgDuration), icon: 'bi-clock', color: 'yellow' }
    ];
  }

  function computeAgentMetrics(fe) {
    const agentMap = {};
    data.agents.forEach(a => {
      agentMap[a.name] = {
        name: a.name, description: a.description, mode: a.mode,
        runs: 0, successes: 0, failures: 0, totalDuration: 0, lastUsed: null,
        skills: new Set()
      };
    });

    fe.agentRuns.forEach(r => {
      if (!agentMap[r.agent]) {
        agentMap[r.agent] = {
          name: r.agent, description: '', mode: '',
          runs: 0, successes: 0, failures: 0, totalDuration: 0, lastUsed: null,
          skills: new Set()
        };
      }
      const a = agentMap[r.agent];
      a.runs++;
      if (r.status === 'success') a.successes++;
      if (r.status === 'failed') a.failures++;
      if (r.duration_ms) a.totalDuration += r.duration_ms;
      if (r.started_at) {
        const d = new Date(r.started_at);
        if (!a.lastUsed || d > a.lastUsed) a.lastUsed = d;
      }
    });

    fe.events.filter(e => e.event === 'SKILL_USED' && e.agent).forEach(e => {
      if (agentMap[e.agent]) agentMap[e.agent].skills.add(e.skill);
    });

    return Object.values(agentMap).map(a => ({
      ...a,
      avgDuration: a.runs ? Math.round(a.totalDuration / a.runs) : 0,
      skills: Array.from(a.skills)
    }));
  }

  function computeMemoryMetrics() {
    const total = data.memory.length;
    const active = data.memory.filter(m => m.status === 'active').length;
    const superseded = data.memory.filter(m => m.status === 'superseded').length;
    const deprecated = data.memory.filter(m => m.status === 'deprecated').length;
    const archived = data.memory.filter(m => m.status === 'archived').length;

    const created = data.events.filter(e => e.event === 'MEMORY_CREATED').length;
    const recalled = data.events.filter(e => e.event === 'MEMORY_RECALLED').length;
    const updated = data.events.filter(e => e.event === 'MEMORY_UPDATED').length;

    return { total, active, superseded, deprecated, archived, created, recalled, updated };
  }

  function computeExecutionMetrics(fe) {
    const total = fe.executions.length;
    const succeeded = fe.executions.filter(e => e.status === 'success').length;
    const failed = fe.executions.filter(e => e.status === 'failed').length;
    const running = fe.executions.filter(e => e.status === 'running').length;

    const durations = fe.executions.filter(e => e.started_at && e.completed_at)
      .map(e => new Date(e.completed_at) - new Date(e.started_at));
    const avgDuration = durations.length ? durations.reduce((a, b) => a + b, 0) / durations.length : 0;

    return { total, succeeded, failed, running, avgDuration };
  }

  function computeHookMetrics(fe) {
    const hookMap = {};
    data.hooks.forEach(h => {
      hookMap[h.name] = { name: h.name, event: h.event, executions: 0, failures: 0, lastExecuted: null };
    });

    fe.events.filter(e => e.event === 'HOOK_COMPLETED').forEach(e => {
      const name = e.hook;
      if (name && hookMap[name]) {
        hookMap[name].executions++;
        if (!hookMap[name].lastExecuted || new Date(e.timestamp) > hookMap[name].lastExecuted) {
          hookMap[name].lastExecuted = new Date(e.timestamp);
        }
      }
    });

    fe.events.filter(e => e.event === 'HOOK_FAILED').forEach(e => {
      const name = e.hook;
      if (name && hookMap[name]) hookMap[name].failures++;
    });

    return Object.values(hookMap);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  function formatDuration(ms) {
    if (!ms || ms === 0) return '0s';
    if (ms < 1000) return Math.round(ms) + 'ms';
    if (ms < 60000) return (ms / 1000).toFixed(1) + 's';
    const mins = Math.floor(ms / 60000);
    const secs = Math.round((ms % 60000) / 1000);
    return `${mins}m ${secs}s`;
  }

  function formatDate(iso) {
    if (!iso) return '—';
    const d = new Date(iso);
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  }

  function formatDateTime(iso) {
    if (!iso) return '—';
    const d = new Date(iso);
    return d.toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  }

  function formatTime(iso) {
    if (!iso) return '';
    const d = new Date(iso);
    return d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  }

  function dayOfWeek(iso) {
    return new Date(iso).toLocaleDateString('en-US', { weekday: 'short' });
  }

  function getKpiHtml(kpis) {
    return kpis.map(k => `
      <div class="kpi-card">
        <div class="kpi-icon ${k.color}"><i class="bi ${k.icon}"></i></div>
        <div>
          <div class="kpi-value">${k.value}</div>
          <div class="kpi-label">${k.label}</div>
        </div>
      </div>
    `).join('');
  }

  function statusBadge(status) {
    const cls = status === 'success' ? 'badge-success' :
                status === 'failed' ? 'badge-failed' :
                status === 'running' ? 'badge-running' : 'badge-pending';
    return `<span class="badge-status ${cls}">${status}</span>`;
  }

  function destroyChart(id) {
    if (chartInstances[id]) {
      chartInstances[id].destroy();
      delete chartInstances[id];
    }
  }

  function createChart(id, config) {
    destroyChart(id);
    const canvas = document.getElementById(id);
    if (!canvas) return null;
    const ctx = canvas.getContext('2d');
    chartInstances[id] = new Chart(ctx, config);
    return chartInstances[id];
  }

  const chartDefaults = {
    color: '#8b8fa3',
    borderColor: '#2a2d3e',
    font: { family: '-apple-system, BlinkMacSystemFont, sans-serif' }
  };

  // ── Navigation ──────────────────────────────────────────────────────────
  function navigateTo(section) {
    currentSection = section;
    document.querySelectorAll('.sidebar-nav .nav-item').forEach(item => {
      item.classList.toggle('active', item.dataset.section === section);
    });
    document.querySelectorAll('.dashboard-section').forEach(sec => {
      sec.classList.toggle('active', sec.id === `section-${section}`);
    });
    document.getElementById('pageTitle').textContent =
      section === 'hooks-events' ? 'Hooks & Events' :
      section.charAt(0).toUpperCase() + section.slice(1).replace('-', ' ');

    renderSection(section);
  }

  window.navigateTo = navigateTo;

  function renderSection(section) {
    const fe = getFilteredData();
    switch (section) {
      case 'overview': renderOverview(fe); break;
      case 'agents': renderAgents(fe); break;
      case 'memory': renderMemory(fe); break;
      case 'executions': renderExecutions(fe); break;
      case 'hooks-events': renderHooksEvents(fe); break;
      case 'analytics': renderAnalytics(fe); break;
    }
  }

  // ── Overview ────────────────────────────────────────────────────────────
  function renderOverview(fe) {
    const kpis = computeOverviewMetrics(fe);
    document.getElementById('overviewKpis').innerHTML = getKpiHtml(kpis);
    renderExecutionTrend(fe);
    renderSuccessFailure(fe);
    renderAgentUsageSummary(fe);
    renderRecentActivity(fe);
    renderRecentExecutions(fe);
  }

  function renderExecutionTrend(fe) {
    const dayMap = {};
    fe.executions.forEach(e => {
      const d = new Date(e.started_at).toLocaleDateString();
      dayMap[d] = (dayMap[d] || 0) + 1;
    });
    const sorted = Object.entries(dayMap).sort((a, b) => new Date(a[0]) - new Date(b[0]));
    const labels = sorted.map(s => new Date(s[0]).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));
    const values = sorted.map(s => s[1]);

    createChart('executionTrendChart', {
      type: 'line',
      data: {
        labels,
        datasets: [{
          label: 'Executions',
          data: values,
          borderColor: '#4f8cff',
          backgroundColor: 'rgba(79,140,255,0.1)',
          fill: true,
          tension: 0.3,
          pointRadius: 3
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3', font: { size: 10 } } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3', stepSize: 1 }, beginAtZero: true }
        }
      }
    });
  }

  function renderSuccessFailure(fe) {
    const success = fe.executions.filter(e => e.status === 'success').length;
    const failed = fe.executions.filter(e => e.status === 'failed').length;
    const other = fe.executions.length - success - failed;

    createChart('successFailureChart', {
      type: 'doughnut',
      data: {
        labels: ['Success', 'Failed', 'Other'],
        datasets: [{
          data: [success, failed, other],
          backgroundColor: ['#34d399', '#f87171', '#5a5e72'],
          borderColor: '#1a1d2e',
          borderWidth: 2
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { color: '#8b8fa3', padding: 12 } } },
        cutout: '65%'
      }
    });
  }

  function renderAgentUsageSummary(fe) {
    const usage = {};
    fe.agentRuns.forEach(r => { usage[r.agent] = (usage[r.agent] || 0) + 1; });
    const sorted = Object.entries(usage).sort((a, b) => b[1] - a[1]);

    createChart('agentUsageSummaryChart', {
      type: 'bar',
      data: {
        labels: sorted.map(s => s[0]),
        datasets: [{
          label: 'Runs',
          data: sorted.map(s => s[1]),
          backgroundColor: '#4f8cff',
          borderRadius: 4
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        indexAxis: 'y',
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true },
          y: { grid: { display: false }, ticks: { color: '#e4e6f0', font: { size: 11 } } }
        }
      }
    });
  }

  function renderRecentActivity(fe) {
    const container = document.getElementById('recentActivity');
    const recent = fe.events.slice(-15).reverse();
    if (!recent.length) {
      container.innerHTML = '<div class="text-muted">No recent activity</div>';
      return;
    }
    container.innerHTML = recent.map(e => `
      <div class="event-item">
        <span class="event-time">${formatTime(e.timestamp)}</span>
        <span class="event-type ${e.event}">${e.event}</span>
        <span class="event-detail">${e.agent || e.hook || e.skill || e.task || ''}</span>
      </div>
    `).join('');
  }

  function renderRecentExecutions(fe) {
    const tbody = document.querySelector('#recentExecutionsTable tbody');
    const recent = fe.executions.slice(-8).reverse();
    if (!recent.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-muted text-center">No executions recorded</td></tr>';
      return;
    }
    tbody.innerHTML = recent.map(e => {
      const dur = e.started_at && e.completed_at
        ? formatDuration(new Date(e.completed_at) - new Date(e.started_at)) : '—';
      return `<tr>
        <td><code>${e.execution_id || '—'}</code></td>
        <td>${truncate(e.task, 40)}</td>
        <td>${e.provider || '—'}</td>
        <td>${formatDateTime(e.started_at)}</td>
        <td>${dur}</td>
        <td>${statusBadge(e.status || 'unknown')}</td>
      </tr>`;
    }).join('');
  }

  // ── Agents ──────────────────────────────────────────────────────────────
  function renderAgents(fe) {
    const agents = computeAgentMetrics(fe);
    const totalRuns = agents.reduce((s, a) => s + a.runs, 0);
    const totalSuccess = agents.reduce((s, a) => s + a.successes, 0);
    const totalFail = agents.reduce((s, a) => s + a.failures, 0);

    document.getElementById('agentsKpis').innerHTML = getKpiHtml([
      { label: 'Total Agents', value: agents.length, icon: 'bi-robot', color: 'blue' },
      { label: 'Total Runs', value: totalRuns, icon: 'bi-play-circle', color: 'purple' },
      { label: 'Successes', value: totalSuccess, icon: 'bi-check-circle', color: 'green' },
      { label: 'Failures', value: totalFail, icon: 'bi-x-circle', color: 'red' }
    ]);

    renderAgentSuccessFailure(fe, agents);
    renderAgentDuration(fe, agents);
    renderAgentHeatmap(fe, agents);
    renderAgentRadar(fe, agents);
    renderAgentRelationshipGraph(agents);
    renderAgentsTable(agents);
  }

  function renderAgentSuccessFailure(fe, agents) {
    const labels = agents.filter(a => a.runs > 0).map(a => a.name);
    const successData = agents.filter(a => a.runs > 0).map(a => a.successes);
    const failData = agents.filter(a => a.runs > 0).map(a => a.failures);

    createChart('agentSuccessFailureChart', {
      type: 'bar',
      data: {
        labels,
        datasets: [
          { label: 'Success', data: successData, backgroundColor: '#34d399', borderRadius: 4 },
          { label: 'Failed', data: failData, backgroundColor: '#f87171', borderRadius: 4 }
        ]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { labels: { color: '#8b8fa3' } } },
        scales: {
          x: { grid: { display: false }, ticks: { color: '#e4e6f0', font: { size: 10 } } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true }
        }
      }
    });
  }

  function renderAgentDuration(fe, agents) {
    const filtered = agents.filter(a => a.avgDuration > 0);

    createChart('agentDurationChart', {
      type: 'bar',
      data: {
        labels: filtered.map(a => a.name),
        datasets: [{
          label: 'Avg Duration (ms)',
          data: filtered.map(a => a.avgDuration),
          backgroundColor: '#a78bfa',
          borderRadius: 4
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, ticks: { color: '#e4e6f0', font: { size: 10 } } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true }
        }
      }
    });
  }

  function renderAgentHeatmap(fe, agents) {
    const container = document.getElementById('agentHeatmap');
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    const grid = {};
    agents.forEach(a => { grid[a.name] = new Array(7).fill(0); });

    fe.agentRuns.forEach(r => {
      if (!grid[r.agent] || !r.started_at) return;
      const day = new Date(r.started_at).getDay();
      const idx = day === 0 ? 6 : day - 1;
      grid[r.agent][idx]++;
    });

    const maxVal = Math.max(1, ...Object.values(grid).flat());
    const cols = dayNames.length + 1;

    let html = `<div class="heatmap-grid" style="grid-template-columns: 100px repeat(${dayNames.length}, 28px);">`;
    html += '<div></div>';
    dayNames.forEach(d => { html += `<div class="heatmap-header">${d}</div>`; });

    Object.entries(grid).forEach(([agent, counts]) => {
      html += `<div class="heatmap-label">${agent}</div>`;
      counts.forEach(v => {
        const intensity = v / maxVal;
        const bg = v === 0 ? 'rgba(42,45,62,0.5)' :
          `rgba(79,140,255,${0.15 + intensity * 0.6})`;
        html += `<div class="heatmap-cell" style="background:${bg}" title="${agent}: ${v}">${v || ''}</div>`;
      });
    });

    html += '</div>';
    container.innerHTML = html;
  }

  function renderAgentRadar(fe, agents) {
    const activeAgents = agents.filter(a => a.runs > 0);
    if (!activeAgents.length) {
      destroyChart('agentRadarChart');
      return;
    }

    const maxRuns = Math.max(1, ...activeAgents.map(a => a.runs));
    const maxDur = Math.max(1, ...activeAgents.map(a => a.avgDuration));

    const datasets = activeAgents.slice(0, 5).map((a, i) => {
      const colors = ['#4f8cff', '#34d399', '#a78bfa', '#fbbf24', '#22d3ee'];
      return {
        label: a.name,
        data: [
          (a.runs / maxRuns) * 100,
          a.runs ? (a.successes / a.runs) * 100 : 0,
          Math.max(0, 100 - (a.avgDuration / maxDur) * 100),
          Math.min(100, a.skills.length * 25),
          Math.min(100, a.runs * 10)
        ],
        borderColor: colors[i],
        backgroundColor: colors[i] + '20',
        pointBackgroundColor: colors[i]
      };
    });

    createChart('agentRadarChart', {
      type: 'radar',
      data: {
        labels: ['Usage', 'Success Rate', 'Speed', 'Skill Diversity', 'Task Coverage'],
        datasets
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { labels: { color: '#8b8fa3' } } },
        scales: {
          r: {
            grid: { color: '#2a2d3e' },
            angleLines: { color: '#2a2d3e' },
            pointLabels: { color: '#8b8fa3', font: { size: 10 } },
            ticks: { display: false },
            suggestedMin: 0, suggestedMax: 100
          }
        }
      }
    });
  }

  function renderAgentRelationshipGraph(agents) {
    const container = document.getElementById('agentRelationshipGraph');
    const active = agents.filter(a => a.skills.length > 0);

    if (!active.length) {
      container.innerHTML = '<div class="text-muted">No agent-skill relationships recorded</div>';
      return;
    }

    container.innerHTML = active.map(a => `
      <div class="network-agent">
        <div class="network-agent-node">${a.name}</div>
        <div class="network-connector"></div>
        <div class="network-skills">
          ${a.skills.map(s => `<div class="network-skill-node">${s}</div>`).join('')}
        </div>
      </div>
    `).join('');
  }

  function renderAgentsTable(agents) {
    const tbody = document.querySelector('#agentsTable tbody');
    if (!agents.length) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-muted text-center">No agents defined</td></tr>';
      return;
    }
    tbody.innerHTML = agents.sort((a, b) => b.runs - a.runs).map(a => `<tr>
      <td><strong>${a.name}</strong></td>
      <td>${truncate(a.description, 50)}</td>
      <td>${a.runs}</td>
      <td>${a.successes}</td>
      <td>${a.failures}</td>
      <td>${a.avgDuration ? formatDuration(a.avgDuration) : '—'}</td>
      <td>${a.lastUsed ? formatDateTime(a.lastUsed.toISOString()) : '—'}</td>
    </tr>`).join('');
  }

  // ── Memory ──────────────────────────────────────────────────────────────
  function renderMemory(fe) {
    const m = computeMemoryMetrics();
    document.getElementById('memoryKpis').innerHTML = getKpiHtml([
      { label: 'Total Memory', value: m.total, icon: 'bi-database', color: 'blue' },
      { label: 'Active', value: m.active, icon: 'bi-check-circle', color: 'green' },
      { label: 'Superseded', value: m.superseded, icon: 'bi-arrow-up-circle', color: 'yellow' },
      { label: 'Deprecated', value: m.deprecated, icon: 'bi-dash-circle', color: 'red' },
      { label: 'Created', value: m.created, icon: 'bi-plus-circle', color: 'cyan' },
      { label: 'Recalled', value: m.recalled, icon: 'bi-search', color: 'purple' }
    ]);

    renderMemoryLifecycle(m);
    renderMemoryGrowth(fe, m);
    renderMemoryType(m);
    renderMemoryActivity(fe, m);
    renderMemoryTable();
  }

  function renderMemoryLifecycle(m) {
    createChart('memoryLifecycleChart', {
      type: 'doughnut',
      data: {
        labels: ['Active', 'Superseded', 'Deprecated', 'Archived'],
        datasets: [{
          data: [m.active, m.superseded, m.deprecated, m.archived],
          backgroundColor: ['#34d399', '#fbbf24', '#f87171', '#5a5e72'],
          borderColor: '#1a1d2e',
          borderWidth: 2
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { color: '#8b8fa3', padding: 10 } } },
        cutout: '60%'
      }
    });
  }

  function renderMemoryGrowth(fe, m) {
    const dayMap = {};
    data.memory.forEach(mem => {
      if (mem.created) {
        const d = new Date(mem.created).toLocaleDateString();
        dayMap[d] = (dayMap[d] || 0) + 1;
      }
    });

    const sorted = Object.entries(dayMap).sort((a, b) => new Date(a[0]) - new Date(b[0]));
    let cumulative = 0;
    const labels = sorted.map(s => new Date(s[0]).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));
    const values = sorted.map(s => { cumulative += s[1]; return cumulative; });

    createChart('memoryGrowthChart', {
      type: 'line',
      data: {
        labels,
        datasets: [{
          label: 'Memory Count',
          data: values,
          borderColor: '#22d3ee',
          backgroundColor: 'rgba(34,211,238,0.1)',
          fill: true,
          tension: 0.3,
          pointRadius: 3
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3', font: { size: 10 } } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true }
        }
      }
    });
  }

  function renderMemoryType(m) {
    const types = {};
    data.memory.forEach(mem => { types[mem.type] = (types[mem.type] || 0) + 1; });

    createChart('memoryTypeChart', {
      type: 'bar',
      data: {
        labels: Object.keys(types),
        datasets: [{
          label: 'Count',
          data: Object.values(types),
          backgroundColor: ['#4f8cff', '#34d399', '#a78bfa', '#fbbf24'],
          borderRadius: 4
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, ticks: { color: '#e4e6f0' } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true }
        }
      }
    });
  }

  function renderMemoryActivity(fe, m) {
    const created = fe.events.filter(e => e.event === 'MEMORY_CREATED');
    const dayMap = {};
    created.forEach(e => {
      const d = new Date(e.timestamp).toLocaleDateString();
      dayMap[d] = (dayMap[d] || 0) + 1;
    });

    const sorted = Object.entries(dayMap).sort((a, b) => new Date(a[0]) - new Date(b[0]));
    const labels = sorted.map(s => new Date(s[0]).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));
    const values = sorted.map(s => s[1]);

    createChart('memoryActivityChart', {
      type: 'bar',
      data: {
        labels,
        datasets: [{
          label: 'Memory Created',
          data: values,
          backgroundColor: '#22d3ee',
          borderRadius: 4
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3', font: { size: 10 } } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true }
        }
      }
    });
  }

  function renderMemoryTable() {
    const tbody = document.querySelector('#memoryTable tbody');
    if (!data.memory.length) {
      tbody.innerHTML = '<tr><td colspan="5" class="text-muted text-center">No memory records</td></tr>';
      return;
    }
    tbody.innerHTML = data.memory.map(m => `<tr>
      <td>${m.type}</td>
      <td>${m.topic}</td>
      <td>${statusBadge(m.status)}</td>
      <td>${m.created ? formatDate(m.created) : '—'}</td>
      <td>${m.updated ? formatDate(m.updated) : '—'}</td>
    </tr>`).join('');
  }

  // ── Executions ──────────────────────────────────────────────────────────
  function renderExecutions(fe) {
    const em = computeExecutionMetrics(fe);
    document.getElementById('executionsKpis').innerHTML = getKpiHtml([
      { label: 'Total', value: em.total, icon: 'bi-play-circle', color: 'blue' },
      { label: 'Success', value: em.succeeded, icon: 'bi-check-circle', color: 'green' },
      { label: 'Failed', value: em.failed, icon: 'bi-x-circle', color: 'red' },
      { label: 'Running', value: em.running, icon: 'bi-hourglass', color: 'yellow' },
      { label: 'Avg Duration', value: formatDuration(em.avgDuration), icon: 'bi-clock', color: 'cyan' }
    ]);

    renderExecutionsTable(fe);
  }

  function renderExecutionsTable(fe) {
    const tbody = document.querySelector('#executionsTable tbody');
    if (!fe.executions.length) {
      tbody.innerHTML = '<tr><td colspan="8" class="text-muted text-center">No executions recorded</td></tr>';
      return;
    }
    tbody.innerHTML = fe.executions.sort((a, b) => new Date(b.started_at) - new Date(a.started_at)).map(e => {
      const dur = e.started_at && e.completed_at
        ? formatDuration(new Date(e.completed_at) - new Date(e.started_at)) : '—';
      return `<tr>
        <td><code>${e.execution_id || '—'}</code></td>
        <td>${truncate(e.task, 50)}</td>
        <td>${e.provider || '—'}</td>
        <td>${formatDateTime(e.started_at)}</td>
        <td>${formatDateTime(e.completed_at)}</td>
        <td>${dur}</td>
        <td>${statusBadge(e.status || 'unknown')}</td>
        <td><button class="btn btn-sm btn-outline-primary" onclick="showExecutionDetail('${e.execution_id}')"><i class="bi bi-eye"></i></button></td>
      </tr>`;
    }).join('');
  }

  // ── Execution Detail ────────────────────────────────────────────────────
  window.showExecutionDetail = function (execId) {
    const exec = data.executions.find(e => e.execution_id === execId);
    if (!exec) return;

    navigateTo('execution-detail');
    document.getElementById('executionDetailTitle').textContent = `Execution: ${execId}`;

    const dur = exec.started_at && exec.completed_at
      ? formatDuration(new Date(exec.completed_at) - new Date(exec.started_at)) : '—';

    document.getElementById('executionInfo').innerHTML = `
      <table class="table table-sm">
        <tr><td class="text-muted">Execution ID</td><td><code>${exec.execution_id}</code></td></tr>
        <tr><td class="text-muted">Session ID</td><td><code>${exec.session_id || '—'}</code></td></tr>
        <tr><td class="text-muted">Task</td><td>${exec.task || '—'}</td></tr>
        <tr><td class="text-muted">Provider</td><td>${exec.provider || '—'}</td></tr>
        <tr><td class="text-muted">Start Time</td><td>${formatDateTime(exec.started_at)}</td></tr>
        <tr><td class="text-muted">End Time</td><td>${formatDateTime(exec.completed_at)}</td></tr>
        <tr><td class="text-muted">Duration</td><td>${dur}</td></tr>
        <tr><td class="text-muted">Status</td><td>${statusBadge(exec.status || 'unknown')}</td></tr>
      </table>
    `;

    renderExecutionTimeline(execId);
    renderAgentFlowGraph(execId);
  };

  function renderExecutionTimeline(execId) {
    const events = data.events
      .filter(e => e.execution_id === execId)
      .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

    const container = document.getElementById('executionTimeline');
    if (!events.length) {
      container.innerHTML = '<div class="text-muted">No events for this execution</div>';
      return;
    }

    container.innerHTML = events.map(e => {
      let cls = '';
      if (e.event.includes('FAILED')) cls = 'failed';
      else if (e.event.includes('COMPLETED')) cls = 'success';
      else if (e.event.includes('HOOK')) cls = 'hook';
      else if (e.event.includes('AGENT')) cls = 'agent';
      else if (e.event.includes('MEMORY')) cls = 'memory';

      const detail = [e.agent, e.hook, e.skill, e.task, e.error].filter(Boolean).join(' — ');

      return `<div class="timeline-item ${cls}">
        <div class="timeline-time">${formatTime(e.timestamp)}</div>
        <div class="timeline-event">${e.event}</div>
        ${detail ? `<div class="timeline-detail">${detail}</div>` : ''}
      </div>`;
    }).join('');
  }

  function renderAgentFlowGraph(execId) {
    const events = data.events
      .filter(e => e.execution_id === execId && e.event === 'AGENT_STARTED')
      .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

    const agentNames = [...new Set(events.map(e => e.agent).filter(Boolean))];
    const container = document.getElementById('agentFlowGraph');

    if (!agentNames.length) {
      container.innerHTML = '<div class="text-muted">No agent flow data</div>';
      return;
    }

    const runs = data.agentRuns.filter(r => r.execution_id === execId);
    const runMap = {};
    runs.forEach(r => { runMap[r.agent] = r; });

    let html = '';
    agentNames.forEach((name, i) => {
      const run = runMap[name];
      const statusCls = run ? (run.status === 'success' ? 'active' : 'failed') : '';
      html += `<div class="flow-node ${statusCls}">
        <div class="flow-node-label">${name}</div>
        ${run ? `<div class="flow-node-detail">${formatDuration(run.duration_ms)}</div>` : ''}
      </div>`;
      if (i < agentNames.length - 1) {
        html += '<div class="flow-arrow"></div>';
      }
    });

    container.innerHTML = html;
  }

  // ── Hooks & Events ──────────────────────────────────────────────────────
  function renderHooksEvents(fe) {
    const hooks = computeHookMetrics(fe);
    const totalHookEvents = fe.events.filter(e => e.event && e.event.startsWith('HOOK')).length;

    document.getElementById('hooksKpis').innerHTML = getKpiHtml([
      { label: 'Configured Hooks', value: data.hooks.length, icon: 'bi-gear', color: 'blue' },
      { label: 'Hook Events', value: totalHookEvents, icon: 'bi-lightning', color: 'yellow' },
      { label: 'Total Events', value: fe.events.length, icon: 'bi-list-ul', color: 'cyan' }
    ]);

    renderEventStream(fe);
    renderEventHeatmap(fe);
    renderHooksTable(hooks);
  }

  function renderEventStream(fe) {
    const container = document.getElementById('eventStream');
    const sorted = [...fe.events].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    if (!sorted.length) {
      container.innerHTML = '<div class="text-muted">No events recorded</div>';
      return;
    }

    container.innerHTML = sorted.map(e => {
      const detail = [e.agent, e.hook, e.skill, e.task, e.error].filter(Boolean).join(' — ');
      return `<div class="event-item">
        <span class="event-time">${formatTime(e.timestamp)}</span>
        <span class="event-type ${e.event}">${e.event}</span>
        <span class="event-detail">${detail}</span>
      </div>`;
    }).join('');
  }

  function renderEventHeatmap(fe) {
    const container = document.getElementById('eventHeatmap');
    const hours = Array.from({ length: 24 }, (_, i) => i);

    const eventTypes = [...new Set(fe.events.map(e => e.event))].slice(0, 10);
    const grid = {};
    eventTypes.forEach(t => { grid[t] = new Array(24).fill(0); });

    fe.events.forEach(e => {
      if (!grid[e.event] || !e.timestamp) return;
      const h = new Date(e.timestamp).getHours();
      grid[e.event][h]++;
    });

    const maxVal = Math.max(1, ...Object.values(grid).flat());

    let html = `<div class="heatmap-grid" style="grid-template-columns: 120px repeat(24, 28px);">`;
    html += '<div></div>';
    hours.forEach(h => {
      html += `<div class="heatmap-header">${h}</div>`;
    });

    eventTypes.forEach(type => {
      html += `<div class="heatmap-label" title="${type}">${type}</div>`;
      grid[type].forEach(v => {
        const intensity = v / maxVal;
        const bg = v === 0 ? 'rgba(42,45,62,0.5)' :
          `rgba(79,140,255,${0.15 + intensity * 0.6})`;
        html += `<div class="heatmap-cell" style="background:${bg}" title="${type} @ ${v}">${v || ''}</div>`;
      });
    });

    html += '</div>';
    container.innerHTML = html;
  }

  function renderHooksTable(hooks) {
    const tbody = document.querySelector('#hooksTable tbody');
    if (!hooks.length) {
      tbody.innerHTML = '<tr><td colspan="5" class="text-muted text-center">No hooks configured</td></tr>';
      return;
    }
    tbody.innerHTML = hooks.map(h => `<tr>
      <td><strong>${h.name}</strong></td>
      <td>${h.event}</td>
      <td>${h.executions}</td>
      <td>${h.failures}</td>
      <td>${h.lastExecuted ? formatDateTime(h.lastExecuted.toISOString()) : '—'}</td>
    </tr>`).join('');
  }

  // ── Analytics ───────────────────────────────────────────────────────────
  function renderAnalytics(fe) {
    renderAnalyticsExecutionsOverTime(fe);
    renderAnalyticsDurationDist(fe);
    renderAnalyticsSkillUsage(fe);
    renderAnalyticsHookFreq(fe);
    renderAnalyticsRetryActivity(fe);
    renderAnalyticsMemoryGrowth(fe);
  }

  function renderAnalyticsExecutionsOverTime(fe) {
    const dayMap = {};
    fe.executions.forEach(e => {
      const d = new Date(e.started_at).toLocaleDateString();
      if (!dayMap[d]) dayMap[d] = { success: 0, failed: 0 };
      if (e.status === 'success') dayMap[d].success++;
      else if (e.status === 'failed') dayMap[d].failed++;
    });

    const sorted = Object.entries(dayMap).sort((a, b) => new Date(a[0]) - new Date(b[0]));
    const labels = sorted.map(s => new Date(s[0]).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));

    createChart('analyticsExecutionsOverTime', {
      type: 'line',
      data: {
        labels,
        datasets: [
          { label: 'Success', data: sorted.map(s => s[1].success), borderColor: '#34d399', tension: 0.3, pointRadius: 2 },
          { label: 'Failed', data: sorted.map(s => s[1].failed), borderColor: '#f87171', tension: 0.3, pointRadius: 2 }
        ]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { labels: { color: '#8b8fa3' } } },
        scales: {
          x: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3', font: { size: 10 } } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true }
        }
      }
    });
  }

  function renderAnalyticsDurationDist(fe) {
    const durations = fe.executions
      .filter(e => e.started_at && e.completed_at)
      .map(e => (new Date(e.completed_at) - new Date(e.started_at)) / 1000);

    const buckets = [0, 10, 30, 60, 120, 300, 600, Infinity];
    const labels = ['<10s', '10-30s', '30-60s', '1-2m', '2-5m', '5-10m', '10m+'];
    const counts = new Array(labels.length).fill(0);

    durations.forEach(d => {
      for (let i = 0; i < buckets.length - 1; i++) {
        if (d >= buckets[i] && d < buckets[i + 1]) { counts[i]++; break; }
      }
    });

    createChart('analyticsDurationDist', {
      type: 'bar',
      data: {
        labels,
        datasets: [{
          label: 'Executions',
          data: counts,
          backgroundColor: '#4f8cff',
          borderRadius: 4
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, ticks: { color: '#e4e6f0', font: { size: 10 } } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true }
        }
      }
    });
  }

  function renderAnalyticsSkillUsage(fe) {
    const skillMap = {};
    fe.events.filter(e => e.event === 'SKILL_USED').forEach(e => {
      if (e.skill) skillMap[e.skill] = (skillMap[e.skill] || 0) + 1;
    });
    const sorted = Object.entries(skillMap).sort((a, b) => b[1] - a[1]);

    createChart('analyticsSkillUsage', {
      type: 'bar',
      data: {
        labels: sorted.map(s => s[0]),
        datasets: [{
          label: 'Times Used',
          data: sorted.map(s => s[1]),
          backgroundColor: '#a78bfa',
          borderRadius: 4
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        indexAxis: 'y',
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true },
          y: { grid: { display: false }, ticks: { color: '#e4e6f0', font: { size: 10 } } }
        }
      }
    });
  }

  function renderAnalyticsHookFreq(fe) {
    const hookMap = {};
    fe.events.filter(e => e.event && e.event.startsWith('HOOK')).forEach(e => {
      const name = e.hook || e.event;
      hookMap[name] = (hookMap[name] || 0) + 1;
    });
    const sorted = Object.entries(hookMap).sort((a, b) => b[1] - a[1]);

    createChart('analyticsHookFreq', {
      type: 'bar',
      data: {
        labels: sorted.map(s => s[0]),
        datasets: [{
          label: 'Events',
          data: sorted.map(s => s[1]),
          backgroundColor: '#fbbf24',
          borderRadius: 4
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, ticks: { color: '#e4e6f0', font: { size: 10 } } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true }
        }
      }
    });
  }

  function renderAnalyticsRetryActivity(fe) {
    const retries = fe.events.filter(e => e.event === 'RETRY');
    const dayMap = {};
    retries.forEach(e => {
      const d = new Date(e.timestamp).toLocaleDateString();
      dayMap[d] = (dayMap[d] || 0) + 1;
    });
    const sorted = Object.entries(dayMap).sort((a, b) => new Date(a[0]) - new Date(b[0]));

    createChart('analyticsRetryActivity', {
      type: 'bar',
      data: {
        labels: sorted.map(s => new Date(s[0]).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })),
        datasets: [{
          label: 'Retries',
          data: sorted.map(s => s[1]),
          backgroundColor: '#f87171',
          borderRadius: 4
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3', font: { size: 10 } } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true }
        }
      }
    });
  }

  function renderAnalyticsMemoryGrowth(fe) {
    const dayMap = {};
    fe.events.filter(e => e.event === 'MEMORY_CREATED').forEach(e => {
      const d = new Date(e.timestamp).toLocaleDateString();
      dayMap[d] = (dayMap[d] || 0) + 1;
    });
    const sorted = Object.entries(dayMap).sort((a, b) => new Date(a[0]) - new Date(b[0]));
    let cumulative = 0;
    const values = sorted.map(s => { cumulative += s[1]; return cumulative; });

    createChart('analyticsMemoryGrowth', {
      type: 'line',
      data: {
        labels: sorted.map(s => new Date(s[0]).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })),
        datasets: [{
          label: 'Memory Records',
          data: values,
          borderColor: '#22d3ee',
          backgroundColor: 'rgba(34,211,238,0.1)',
          fill: true,
          tension: 0.3,
          pointRadius: 3
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3', font: { size: 10 } } },
          y: { grid: { color: '#2a2d3e' }, ticks: { color: '#8b8fa3' }, beginAtZero: true }
        }
      }
    });
  }

  // ── Truncate Helper ─────────────────────────────────────────────────────
  function truncate(str, len) {
    if (!str) return '';
    return str.length > len ? str.slice(0, len) + '...' : str;
  }

  // ── Event Listeners ─────────────────────────────────────────────────────
  function initEventListeners() {
    // Sidebar navigation
    document.querySelectorAll('.sidebar-nav .nav-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        navigateTo(item.dataset.section);
      });
    });

    // Sidebar toggle (mobile)
    document.getElementById('sidebarToggle').addEventListener('click', () => {
      document.getElementById('sidebar').classList.toggle('open');
    });

    // Refresh
    document.getElementById('refreshBtn').addEventListener('click', async () => {
      const btn = document.getElementById('refreshBtn');
      btn.disabled = true;
      btn.innerHTML = '<i class="bi bi-arrow-clockwise spin"></i> Loading...';

      // Reset data
      data.executions = [];
      data.events = [];
      data.agentRuns = [];
      data.agents = [];
      data.skills = [];
      data.hooks = [];
      data.memory = [];

      await loadAllData();
      renderSection(currentSection);

      btn.disabled = false;
      btn.innerHTML = '<i class="bi bi-arrow-clockwise"></i> Refresh';
    });

    // Date filters
    document.getElementById('filterStartDate').addEventListener('change', (e) => {
      filters.startDate = e.target.value || null;
      renderSection(currentSection);
    });
    document.getElementById('filterEndDate').addEventListener('change', (e) => {
      filters.endDate = e.target.value || null;
      renderSection(currentSection);
    });

    // Quick range buttons
    document.querySelectorAll('[data-range]').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('[data-range]').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');

        const range = btn.dataset.range;
        const now = new Date();
        if (range === 'today') {
          filters.startDate = now.toISOString().split('T')[0];
          filters.endDate = filters.startDate;
        } else if (range === '7d') {
          const d = new Date(now);
          d.setDate(d.getDate() - 7);
          filters.startDate = d.toISOString().split('T')[0];
          filters.endDate = now.toISOString().split('T')[0];
        } else if (range === '30d') {
          const d = new Date(now);
          d.setDate(d.getDate() - 30);
          filters.startDate = d.toISOString().split('T')[0];
          filters.endDate = now.toISOString().split('T')[0];
        } else {
          filters.startDate = null;
          filters.endDate = null;
        }

        document.getElementById('filterStartDate').value = filters.startDate || '';
        document.getElementById('filterEndDate').value = filters.endDate || '';
        renderSection(currentSection);
      });
    });

    // Select filters
    document.getElementById('filterProvider').addEventListener('change', (e) => {
      filters.provider = e.target.value;
      renderSection(currentSection);
    });
    document.getElementById('filterAgent').addEventListener('change', (e) => {
      filters.agent = e.target.value;
      renderSection(currentSection);
    });
    document.getElementById('filterStatus').addEventListener('change', (e) => {
      filters.status = e.target.value;
      renderSection(currentSection);
    });
    document.getElementById('filterEventType').addEventListener('change', (e) => {
      filters.eventType = e.target.value;
      renderSection(currentSection);
    });
  }

  // ── Initialize ──────────────────────────────────────────────────────────
  document.addEventListener('DOMContentLoaded', async () => {
    initEventListeners();
    await loadAllData();
    renderSection('overview');
  });

})();
