#!/usr/bin/env python3
"""
generate_compatibility_page.py
Generates docs/website/compatibility.html from data/profiles/*.json.
Can also check if the generated HTML is up-to-date (--check flag).
"""

import os
import sys
import glob
import json
import argparse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_PROFILES_DIR = os.path.join(REPO_ROOT, "data", "profiles")
OUTPUT_HTML_PATH = os.path.join(REPO_ROOT, "docs", "website", "compatibility.html")

def load_profiles(profiles_dir):
    profiles = []
    pattern = os.path.join(profiles_dir, "*.json")
    for file_path in sorted(glob.glob(pattern)):
        if os.path.basename(file_path) == "schema.json":
            continue
        with open(file_path, "r", encoding="utf-8") as f:
            try:
                data = json.load(f)
                profiles.append(data)
            except Exception as e:
                print(f"Error parsing {file_path}: {e}", file=sys.stderr)
                sys.exit(1)
    return profiles

def calculate_counts(profiles):
    total = len(profiles)
    verified = sum(1 for p in profiles if p.get("confidence_level") == "verified")
    native = sum(1 for p in profiles if p.get("compatibility_status") == "native_macos")
    likely = sum(1 for p in profiles if p.get("compatibility_status") == "likely_compatible")
    requires_win = sum(1 for p in profiles if p.get("compatibility_status") == "requires_windows")
    not_supported = sum(1 for p in profiles if p.get("compatibility_status") == "not_supported")
    playable = native + likely
    blocked = sum(1 for p in profiles if p.get("launch_policy") == "block_kernel_anticheat" or 
                  (p.get("anti_cheat", {}).get("type") == "kernel_ring0" and not p.get("anti_cheat", {}).get("offline_mode_allowed")))
    return {
        "total": total,
        "verified": verified,
        "native": native,
        "likely": likely,
        "requires_win": requires_win,
        "not_supported": not_supported,
        "playable": playable,
        "blocked": blocked
    }

def generate_html(profiles):
    profiles_sorted = sorted(profiles, key=lambda p: p.get("name", ""))
    counts = calculate_counts(profiles_sorted)

    rows = []
    for p in profiles_sorted:
        status = p.get("compatibility_status", "")
        if status == "native_macos":
            status_cls = "badge-native"
            status_lbl = "Native macOS"
        elif status == "likely_compatible":
            status_cls = "badge-likely"
            status_lbl = "Likely Compatible"
        elif status == "requires_windows":
            status_cls = "badge-windows"
            status_lbl = "Requires Windows"
        else:
            status_cls = "badge-blocked"
            status_lbl = "Not Supported"

        ac = p.get("anti_cheat", {})
        ac_type = ac.get("type", "none")
        if ac_type == "kernel_ring0":
            ac_cat = "kernel"
            ac_cls = "badge-ac-kernel"
        elif ac_type == "userspace":
            ac_cat = "userspace"
            ac_cls = "badge-ac-userspace"
        else:
            ac_cat = "none"
            ac_cls = "badge-ac-none"

        policy = p.get("launch_policy", "")
        if policy == "allow_direct":
            policy_cls = "badge-policy-direct"
            policy_lbl = "Direct Launch"
        elif policy == "allow_offline_only":
            policy_cls = "badge-policy-offline"
            policy_lbl = "Offline Only"
        else:
            policy_cls = "badge-policy-blocked"
            policy_lbl = "Sentinel Blocked"

        steam_app_id = p.get("steam_app_id")
        if steam_app_id:
            steam_link = f'<a href="https://store.steampowered.com/app/{steam_app_id}/" target="_blank" class="link-steam">Steam #{steam_app_id}</a>'
        else:
            steam_link = '<span class="text-muted">Standalone</span>'

        sources_links = " ".join([
            f'<a href="{src}" target="_blank" class="link-source" title="{src}">[{idx + 1}]</a>'
            for idx, src in enumerate(p.get("sources", []))
        ])

        backend = p.get("recommended_runtime", {}).get("graphics_backend", "N/A")
        offline_ok = "Offline OK" if ac.get("offline_mode_allowed") else "Online Only"
        game_id = p.get("id", "")
        game_name = p.get("name", "")
        publisher = p.get("publisher", "")
        policy_notice = p.get("policy_notice", "")

        row = f"""            <tr class="game-row" data-id="{game_id}" data-title="{game_name.lower()}" data-publisher="{publisher.lower()}" data-status="{status}" data-anticheat="{ac_cat}" data-policy="{policy}">
              <td class="col-game">
                <div class="game-title">{game_name}</div>
                <div class="game-publisher">{publisher} &bull; {steam_link}</div>
              </td>
              <td class="col-status">
                <span class="status-badge {status_cls}">{status_lbl}</span>
              </td>
              <td class="col-anticheat">
                <span class="ac-badge {ac_cls}">{ac.get('name', 'None')}</span>
                <div class="ac-type">{ac_type} &bull; {offline_ok}</div>
              </td>
              <td class="col-policy">
                <span class="policy-badge {policy_cls}">{policy_lbl}</span>
              </td>
              <td class="col-runtime">
                <code>{backend}</code>
              </td>
              <td class="col-notice">
                <p class="policy-notice-text">{policy_notice}</p>
                <div class="sources-links">Sources: {sources_links}</div>
              </td>
            </tr>"""
        rows.append(row)

    rows_html = "\n".join(rows)

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Compatibility Matrix &bull; MacOSGaming (Apple Silicon)</title>
  <meta name="description" content="Verified game compatibility matrix for Windows PC and native games running on Apple Silicon (M1-M4) Macs via MacOSGaming.">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    :root {{
      --bg: #090d16;
      --card-bg: rgba(18, 24, 38, 0.7);
      --card-border: rgba(255, 255, 255, 0.08);
      --primary: #3b82f6;
      --primary-glow: rgba(59, 130, 246, 0.35);
      --accent: #06b6d4;
      --success: #10b981;
      --warning: #f59e0b;
      --danger: #ef4444;
      --text: #f8fafc;
      --text-muted: #94a3b8;
      --font-sans: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      --font-mono: 'JetBrains Mono', Menlo, monospace;
    }}

    * {{
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }}

    body {{
      background-color: var(--bg);
      color: var(--text);
      font-family: var(--font-sans);
      line-height: 1.6;
      background-image: 
        radial-gradient(at 0% 0%, rgba(59, 130, 246, 0.12) 0px, transparent 50%),
        radial-gradient(at 100% 100%, rgba(6, 182, 212, 0.08) 0px, transparent 50%);
      min-height: 100vh;
    }}

    .container {{
      max-width: 1280px;
      margin: 0 auto;
      padding: 0 24px;
    }}

    /* Header */
    header {{
      position: sticky;
      top: 0;
      z-index: 100;
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      background: rgba(9, 13, 22, 0.85);
      border-bottom: 1px solid var(--card-border);
      padding: 16px 0;
    }}

    .nav-inner {{
      display: flex;
      justify-content: space-between;
      align-items: center;
    }}

    .brand {{
      display: flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      color: var(--text);
      font-weight: 700;
      font-size: 1.25rem;
    }}

    .brand-badge {{
      font-size: 0.75rem;
      padding: 2px 8px;
      border-radius: 999px;
      background: rgba(59, 130, 246, 0.15);
      color: var(--primary);
      border: 1px solid rgba(59, 130, 246, 0.3);
    }}

    nav {{
      display: flex;
      gap: 20px;
      align-items: center;
    }}

    nav a {{
      color: var(--text-muted);
      text-decoration: none;
      font-size: 0.95rem;
      font-weight: 500;
      transition: color 0.2s;
    }}

    nav a:hover, nav a.active {{
      color: var(--text);
    }}

    .btn {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 16px;
      border-radius: 8px;
      font-size: 0.9rem;
      font-weight: 600;
      text-decoration: none;
      transition: all 0.2s;
    }}

    .btn-primary {{
      background: var(--primary);
      color: #fff;
      border: 1px solid var(--primary);
    }}

    .btn-primary:hover {{
      box-shadow: 0 0 16px var(--primary-glow);
      transform: translateY(-1px);
    }}

    /* Page Title & Stats */
    .page-header {{
      padding: 48px 0 24px;
    }}

    .hero-tag {{
      display: inline-block;
      font-size: 0.8rem;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      font-weight: 700;
      color: var(--accent);
      margin-bottom: 8px;
    }}

    h1 {{
      font-size: 2.5rem;
      font-weight: 800;
      letter-spacing: -0.02em;
      margin-bottom: 12px;
    }}

    .subtitle {{
      color: var(--text-muted);
      font-size: 1.1rem;
      max-width: 800px;
      margin-bottom: 32px;
    }}

    .stats-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 16px;
      margin-bottom: 36px;
    }}

    .stat-card {{
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 20px;
      backdrop-filter: blur(12px);
    }}

    .stat-num {{
      font-size: 2rem;
      font-weight: 800;
      color: var(--text);
      margin-bottom: 4px;
    }}

    .stat-label {{
      font-size: 0.85rem;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      font-weight: 600;
    }}

    /* Filter & Search Toolbar */
    .toolbar {{
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 16px;
      margin-bottom: 24px;
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
      align-items: center;
      justify-content: space-between;
    }}

    .search-box {{
      flex: 1;
      min-width: 260px;
      position: relative;
    }}

    .search-box input {{
      width: 100%;
      padding: 10px 16px 10px 40px;
      background: rgba(0, 0, 0, 0.3);
      border: 1px solid var(--card-border);
      border-radius: 8px;
      color: var(--text);
      font-family: var(--font-sans);
      font-size: 0.95rem;
      outline: none;
      transition: border-color 0.2s;
    }}

    .search-box input:focus {{
      border-color: var(--primary);
    }}

    .search-icon {{
      position: absolute;
      left: 14px;
      top: 50%;
      transform: translateY(-50%);
      color: var(--text-muted);
      font-size: 1rem;
    }}

    .filter-group {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      align-items: center;
    }}

    .filter-btn {{
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid var(--card-border);
      color: var(--text-muted);
      padding: 8px 14px;
      border-radius: 8px;
      font-size: 0.85rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }}

    .filter-btn:hover {{
      background: rgba(255, 255, 255, 0.08);
      color: var(--text);
    }}

    .filter-btn.active {{
      background: var(--primary);
      border-color: var(--primary);
      color: #fff;
    }}

    select.filter-select {{
      background: rgba(0, 0, 0, 0.3);
      border: 1px solid var(--card-border);
      color: var(--text);
      padding: 8px 12px;
      border-radius: 8px;
      font-family: var(--font-sans);
      font-size: 0.85rem;
      outline: none;
      cursor: pointer;
    }}

    /* Table Styles */
    .table-wrapper {{
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      overflow-x: auto;
      margin-bottom: 48px;
    }}

    table {{
      width: 100%;
      border-collapse: collapse;
      text-align: left;
    }}

    thead {{
      background: rgba(0, 0, 0, 0.25);
      border-bottom: 1px solid var(--card-border);
    }}

    th {{
      padding: 14px 18px;
      font-size: 0.8rem;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      color: var(--text-muted);
      font-weight: 700;
    }}

    tbody tr {{
      border-bottom: 1px solid rgba(255, 255, 255, 0.04);
      transition: background 0.15s;
    }}

    tbody tr:hover {{
      background: rgba(255, 255, 255, 0.02);
    }}

    td {{
      padding: 16px 18px;
      vertical-align: top;
      font-size: 0.9rem;
    }}

    .game-title {{
      font-weight: 700;
      font-size: 1rem;
      color: var(--text);
      margin-bottom: 2px;
    }}

    .game-publisher {{
      font-size: 0.8rem;
      color: var(--text-muted);
    }}

    .link-steam {{
      color: var(--accent);
      text-decoration: none;
    }}

    .link-steam:hover {{
      text-decoration: underline;
    }}

    .link-source {{
      color: var(--primary);
      text-decoration: none;
      font-family: var(--font-mono);
      font-size: 0.8rem;
    }}

    .link-source:hover {{
      text-decoration: underline;
    }}

    /* Badges */
    .status-badge {{
      display: inline-block;
      padding: 4px 10px;
      border-radius: 6px;
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      white-space: nowrap;
    }}

    .badge-native {{
      background: rgba(16, 185, 129, 0.15);
      color: #34d399;
      border: 1px solid rgba(16, 185, 129, 0.3);
    }}

    .badge-likely {{
      background: rgba(59, 130, 246, 0.15);
      color: #60a5fa;
      border: 1px solid rgba(59, 130, 246, 0.3);
    }}

    .badge-windows {{
      background: rgba(245, 158, 11, 0.15);
      color: #fbbf24;
      border: 1px solid rgba(245, 158, 11, 0.3);
    }}

    .badge-blocked {{
      background: rgba(239, 68, 68, 0.15);
      color: #f87171;
      border: 1px solid rgba(239, 68, 68, 0.3);
    }}

    .ac-badge {{
      display: inline-block;
      font-size: 0.8rem;
      font-weight: 600;
    }}

    .badge-ac-kernel {{
      color: #f87171;
    }}

    .badge-ac-userspace {{
      color: #fbbf24;
    }}

    .badge-ac-none {{
      color: #34d399;
    }}

    .ac-type {{
      font-size: 0.75rem;
      color: var(--text-muted);
      margin-top: 2px;
    }}

    .policy-badge {{
      display: inline-block;
      padding: 3px 8px;
      border-radius: 4px;
      font-size: 0.75rem;
      font-weight: 600;
      white-space: nowrap;
    }}

    .badge-policy-direct {{
      background: rgba(16, 185, 129, 0.1);
      color: #34d399;
    }}

    .badge-policy-offline {{
      background: rgba(245, 158, 11, 0.1);
      color: #fbbf24;
    }}

    .badge-policy-blocked {{
      background: rgba(239, 68, 68, 0.1);
      color: #f87171;
    }}

    code {{
      font-family: var(--font-mono);
      font-size: 0.8rem;
      background: rgba(0, 0, 0, 0.4);
      padding: 2px 6px;
      border-radius: 4px;
      color: #e2e8f0;
    }}

    .policy-notice-text {{
      font-size: 0.8rem;
      color: #cbd5e1;
      line-height: 1.5;
      margin-bottom: 6px;
    }}

    .sources-links {{
      font-size: 0.75rem;
      color: var(--text-muted);
    }}

    .no-results {{
      padding: 48px;
      text-align: center;
      color: var(--text-muted);
      font-size: 1.1rem;
      display: none;
    }}

    /* Footer */
    footer {{
      border-top: 1px solid var(--card-border);
      padding: 36px 0;
      text-align: center;
      font-size: 0.85rem;
      color: var(--text-muted);
    }}

    footer a {{
      color: var(--text);
      text-decoration: none;
    }}

    footer a:hover {{
      text-decoration: underline;
    }}
  </style>
</head>
<body>

  <!-- Header -->
  <header>
    <div class="container nav-inner">
      <a href="index.html" class="brand">
        <span>🎮 MacOSGaming</span>
        <span class="brand-badge">v0.1.1</span>
      </a>
      <nav>
        <a href="index.html">Overview</a>
        <a href="index.html#features">Features</a>
        <a href="compatibility.html" class="active">Compatibility Matrix</a>
        <a href="https://github.com/NicolasBecasAzagra/MacOSGaming/issues/new?template=game_report.yml" target="_blank" class="btn btn-primary">+ Submit Game Report</a>
      </nav>
    </div>
  </header>

  <!-- Main Content -->
  <main class="container">
    <div class="page-header">
      <span class="hero-tag">Verified Compatibility Matrix &bull; Apple Silicon M1-M4</span>
      <h1>Game Compatibility on macOS</h1>
      <p class="subtitle">
        Independent, verified technical compatibility profiles for Windows and native PC games running on Apple Silicon Macs. 
        Filter by launch policy, graphics runtime, and anti-cheat mechanism.
      </p>

      <!-- Statistics -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-num" id="stat-total">{counts['total']}</div>
          <div class="stat-label">Profiles Cataloged</div>
        </div>
        <div class="stat-card">
          <div class="stat-num" style="color: #34d399;" id="stat-verified">{counts['verified']}</div>
          <div class="stat-label">Verified Confidence</div>
        </div>
        <div class="stat-card">
          <div class="stat-num" style="color: #60a5fa;" id="stat-playable">{counts['playable']}</div>
          <div class="stat-label">Playable on Apple Silicon</div>
        </div>
        <div class="stat-card">
          <div class="stat-num" style="color: #f87171;" id="stat-blocked">{counts['blocked']}</div>
          <div class="stat-label">Kernel Anti-Cheat Blocked</div>
        </div>
      </div>

      <!-- Filter Toolbar -->
      <div class="toolbar">
        <div class="search-box">
          <span class="search-icon">🔍</span>
          <input type="text" id="search-input" placeholder="Search by game title, publisher, or ID..." autocomplete="off">
        </div>

        <div class="filter-group">
          <button class="filter-btn active" data-filter="all">All Games</button>
          <button class="filter-btn" data-filter="native_macos">Native macOS</button>
          <button class="filter-btn" data-filter="likely_compatible">Likely Compatible</button>
          <button class="filter-btn" data-filter="requires_windows">Requires Windows</button>
          <button class="filter-btn" data-filter="not_supported">Not Supported</button>
        </div>

        <div>
          <select class="filter-select" id="anticheat-select">
            <option value="all">All Anti-Cheat Types</option>
            <option value="none">No Anti-Cheat (Offline)</option>
            <option value="userspace">Userspace (VAC)</option>
            <option value="kernel">Kernel Ring-0 (EAC / BattlEye / Vanguard)</option>
          </select>
        </div>
      </div>

      <!-- Table -->
      <div class="table-wrapper">
        <table id="matrix-table">
          <thead>
            <tr>
              <th style="min-width: 220px;">Game & Publisher</th>
              <th style="min-width: 150px;">Status</th>
              <th style="min-width: 180px;">Anti-Cheat</th>
              <th style="min-width: 140px;">Launch Policy</th>
              <th style="min-width: 120px;">Runtime</th>
              <th style="min-width: 340px;">Policy Notice & Verification</th>
            </tr>
          </thead>
          <tbody id="matrix-tbody">
{rows_html}
          </tbody>
        </table>
        <div class="no-results" id="no-results">
          No games match your search or filter criteria.
        </div>
      </div>
    </div>
  </main>

  <!-- Footer -->
  <footer>
    <div class="container">
      <p>
        MacOSGaming is open-source software released under the <a href="https://github.com/NicolasBecasAzagra/MacOSGaming/blob/main/LICENSE" target="_blank">MIT License</a>.
      </p>
      <p style="margin-top: 8px;">
        Have test results for a game? <a href="https://github.com/NicolasBecasAzagra/MacOSGaming/issues/new?template=game_report.yml" target="_blank">Submit a Community Game Report</a>.
      </p>
    </div>
  </footer>

  <!-- Interactive Filtering Script -->
  <script>
    (function() {{
      const searchInput = document.getElementById('search-input');
      const filterBtns = document.querySelectorAll('.filter-btn');
      const anticheatSelect = document.getElementById('anticheat-select');
      const rows = document.querySelectorAll('#matrix-tbody tr');
      const noResults = document.getElementById('no-results');

      let activeStatus = 'all';
      let activeAntiCheat = 'all';
      let searchQuery = '';

      function applyFilters() {{
        let visibleCount = 0;
        rows.forEach(row => {{
          const title = row.getAttribute('data-title') || '';
          const publisher = row.getAttribute('data-publisher') || '';
          const id = row.getAttribute('data-id') || '';
          const status = row.getAttribute('data-status') || '';
          const anticheat = row.getAttribute('data-anticheat') || '';

          const matchesSearch = !searchQuery || 
            title.includes(searchQuery) || 
            publisher.includes(searchQuery) || 
            id.includes(searchQuery);

          const matchesStatus = activeStatus === 'all' || status === activeStatus;
          const matchesAntiCheat = activeAntiCheat === 'all' || anticheat === activeAntiCheat;

          if (matchesSearch && matchesStatus && matchesAntiCheat) {{
            row.style.display = '';
            visibleCount++;
          }} else {{
            row.style.display = 'none';
          }}
        }});

        noResults.style.display = visibleCount === 0 ? 'block' : 'none';
      }}

      searchInput.addEventListener('input', e => {{
        searchQuery = e.target.value.toLowerCase().trim();
        applyFilters();
      }});

      filterBtns.forEach(btn => {{
        btn.addEventListener('click', () => {{
          filterBtns.forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          activeStatus = btn.getAttribute('data-filter');
          applyFilters();
        }});
      }});

      anticheatSelect.addEventListener('change', e => {{
        activeAntiCheat = e.target.value;
        applyFilters();
      }});
    }})();
  </script>
</body>
</html>
"""
    return html

def main():
    parser = argparse.ArgumentParser(description="Generate compatibility matrix HTML page.")
    parser.add_argument("--check", action="store_true", help="Check if generated file is up-to-date without modifying.")
    parser.add_argument("--output", default=OUTPUT_HTML_PATH, help="Path to output HTML.")
    args = parser.parse_args()

    profiles = load_profiles(DATA_PROFILES_DIR)
    counts = calculate_counts(profiles)
    html = generate_html(profiles)

    if args.check:
        if not os.path.exists(args.output):
            print(f"Error: {args.output} does not exist.", file=sys.stderr)
            sys.exit(1)
        with open(args.output, "r", encoding="utf-8") as f:
            existing_html = f.read()
        if existing_html.strip() != html.strip():
            print(f"Error: {args.output} is out of date. Run python3 scripts/generate_compatibility_page.py to update.", file=sys.stderr)
            sys.exit(1)
        print("OK: Compatibility matrix HTML is up-to-date.")
        sys.exit(0)

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"Successfully generated {args.output}")
    print(f"Profiles: {counts['total']} | Verified: {counts['verified']} | Playable: {counts['playable']} | Blocked: {counts['blocked']}")

if __name__ == "__main__":
    main()
