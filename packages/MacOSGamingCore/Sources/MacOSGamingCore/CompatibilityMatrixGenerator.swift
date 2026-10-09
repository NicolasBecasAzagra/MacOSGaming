import Foundation

public struct CompatibilityMatrixGenerator: Sendable {
    public struct BadgeCounts: Equatable, Sendable {
        public let total: Int
        public let verified: Int
        public let nativeMacOS: Int
        public let likelyCompatible: Int
        public let requiresWindows: Int
        public let notSupported: Int
        public let playableTotal: Int
        public let blockedByAntiCheat: Int

        public init(
            total: Int,
            verified: Int,
            nativeMacOS: Int,
            likelyCompatible: Int,
            requiresWindows: Int,
            notSupported: Int,
            playableTotal: Int,
            blockedByAntiCheat: Int
        ) {
            self.total = total
            self.verified = verified
            self.nativeMacOS = nativeMacOS
            self.likelyCompatible = likelyCompatible
            self.requiresWindows = requiresWindows
            self.notSupported = notSupported
            self.playableTotal = playableTotal
            self.blockedByAntiCheat = blockedByAntiCheat
        }
    }

    public static func calculateBadgeCounts(profiles: [GameProfile]) -> BadgeCounts {
        let total = profiles.count
        let verified = profiles.filter { $0.confidenceLevel == .verified }.count
        let native = profiles.filter { $0.compatibilityStatus == .nativeMacOS }.count
        let likely = profiles.filter { $0.compatibilityStatus == .likelyCompatible }.count
        let requiresWin = profiles.filter { $0.compatibilityStatus == .requiresWindows }.count
        let notSupp = profiles.filter { $0.compatibilityStatus == .notSupported }.count
        let playable = native + likely
        let blocked = profiles.filter {
            $0.launchPolicy == .blockKernelAnticheat ||
            ($0.antiCheat.type == .kernelRing0 && !$0.antiCheat.offlineModeAllowed)
        }.count

        return BadgeCounts(
            total: total,
            verified: verified,
            nativeMacOS: native,
            likelyCompatible: likely,
            requiresWindows: requiresWin,
            notSupported: notSupp,
            playableTotal: playable,
            blockedByAntiCheat: blocked
        )
    }

    public static func generateBadgesMarkdown(counts: BadgeCounts) -> String {
        return """
        [![Game Profiles](https://img.shields.io/badge/Profiles-\(counts.total)%20Cataloged-blue?style=flat-square&logo=apple)](https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html)
        [![Confidence](https://img.shields.io/badge/Confidence-\(counts.verified)%20Verified-brightgreen?style=flat-square&logo=checkmarx)](https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html)
        [![Playable on Mac](https://img.shields.io/badge/Playable-\(counts.playableTotal)%20Supported-success?style=flat-square&logo=speedtest)](https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html)
        [![Blocked by Anti-Cheat](https://img.shields.io/badge/Blocked-\(counts.blockedByAntiCheat)%20Kernel%20Anti--Cheat-critical?style=flat-square&logo=shield)](https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html)
        """
    }

    public static func generateHTML(profiles: [GameProfile]) -> String {
        let sortedProfiles = profiles.sorted { $0.name < $1.name }
        let counts = calculateBadgeCounts(profiles: sortedProfiles)

        var rowsHtml = ""
        for p in sortedProfiles {
            let statusBadgeClass: String
            let statusLabel: String
            switch p.compatibilityStatus {
            case .nativeMacOS:
                statusBadgeClass = "badge-native"
                statusLabel = "Native macOS"
            case .likelyCompatible:
                statusBadgeClass = "badge-likely"
                statusLabel = "Likely Compatible"
            case .requiresWindows:
                statusBadgeClass = "badge-windows"
                statusLabel = "Requires Windows"
            case .notSupported:
                statusBadgeClass = "badge-blocked"
                statusLabel = "Not Supported"
            }

            let antiCheatCategory: String
            let antiCheatBadgeClass: String
            switch p.antiCheat.type {
            case .kernelRing0:
                antiCheatCategory = "kernel"
                antiCheatBadgeClass = "badge-ac-kernel"
            case .userspace:
                antiCheatCategory = "userspace"
                antiCheatBadgeClass = "badge-ac-userspace"
            case .none:
                antiCheatCategory = "none"
                antiCheatBadgeClass = "badge-ac-none"
            }

            let policyBadgeClass: String
            let policyLabel: String
            switch p.launchPolicy {
            case .allowDirect:
                policyBadgeClass = "badge-policy-direct"
                policyLabel = "Direct Launch"
            case .allowOfflineOnly:
                policyBadgeClass = "badge-policy-offline"
                policyLabel = "Offline Only"
            case .blockKernelAnticheat:
                policyBadgeClass = "badge-policy-blocked"
                policyLabel = "Sentinel Blocked"
            }

            let steamLink = p.steamAppId != nil
                ? "<a href=\"https://store.steampowered.com/app/\(p.steamAppId!)/\" target=\"_blank\" class=\"link-steam\">Steam #\(p.steamAppId!)</a>"
                : "<span class=\"text-muted\">Standalone</span>"

            var sourcesHtml = ""
            for (idx, src) in p.sources.enumerated() {
                sourcesHtml += "<a href=\"\(src)\" target=\"_blank\" class=\"link-source\" title=\"\(src)\">[\(idx + 1)]</a> "
            }

            let row = """
            <tr class="game-row" data-id="\(p.id)" data-title="\(p.name.lowercased())" data-publisher="\(p.publisher.lowercased())" data-status="\(p.compatibilityStatus.rawValue)" data-anticheat="\(antiCheatCategory)" data-policy="\(p.launchPolicy.rawValue)">
              <td class="col-game">
                <div class="game-title">\(p.name)</div>
                <div class="game-publisher">\(p.publisher) &bull; \(steamLink)</div>
              </td>
              <td class="col-status">
                <span class="status-badge \(statusBadgeClass)">\(statusLabel)</span>
              </td>
              <td class="col-anticheat">
                <span class="ac-badge \(antiCheatBadgeClass)">\(p.antiCheat.name)</span>
                <div class="ac-type">\(p.antiCheat.type.rawValue) &bull; \(p.antiCheat.offlineModeAllowed ? "Offline OK" : "Online Only")</div>
              </td>
              <td class="col-policy">
                <span class="policy-badge \(policyBadgeClass)">\(policyLabel)</span>
              </td>
              <td class="col-runtime">
                <code>\(p.recommendedRuntime.graphicsBackend.rawValue)</code>
              </td>
              <td class="col-notice">
                <p class="policy-notice-text">\(p.policyNotice)</p>
                <div class="sources-links">Sources: \(sourcesHtml)</div>
              </td>
            </tr>
            """
            rowsHtml += row + "\n"
        }

        return """
        <!DOCTYPE html>
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
            :root {
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
            }

            * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
            }

            body {
              background-color: var(--bg);
              color: var(--text);
              font-family: var(--font-sans);
              line-height: 1.6;
              background-image: 
                radial-gradient(at 0% 0%, rgba(59, 130, 246, 0.12) 0px, transparent 50%),
                radial-gradient(at 100% 100%, rgba(6, 182, 212, 0.08) 0px, transparent 50%);
              min-height: 100vh;
            }

            .container {
              max-width: 1280px;
              margin: 0 auto;
              padding: 0 24px;
            }

            /* Header */
            header {
              position: sticky;
              top: 0;
              z-index: 100;
              backdrop-filter: blur(16px);
              -webkit-backdrop-filter: blur(16px);
              background: rgba(9, 13, 22, 0.85);
              border-bottom: 1px solid var(--card-border);
              padding: 16px 0;
            }

            .nav-inner {
              display: flex;
              justify-content: space-between;
              align-items: center;
            }

            .brand {
              display: flex;
              align-items: center;
              gap: 12px;
              text-decoration: none;
              color: var(--text);
              font-weight: 700;
              font-size: 1.25rem;
            }

            .brand-badge {
              font-size: 0.75rem;
              padding: 2px 8px;
              border-radius: 999px;
              background: rgba(59, 130, 246, 0.15);
              color: var(--primary);
              border: 1px solid rgba(59, 130, 246, 0.3);
            }

            nav {
              display: flex;
              gap: 20px;
              align-items: center;
            }

            nav a {
              color: var(--text-muted);
              text-decoration: none;
              font-size: 0.95rem;
              font-weight: 500;
              transition: color 0.2s;
            }

            nav a:hover, nav a.active {
              color: var(--text);
            }

            .btn {
              display: inline-flex;
              align-items: center;
              gap: 8px;
              padding: 8px 16px;
              border-radius: 8px;
              font-size: 0.9rem;
              font-weight: 600;
              text-decoration: none;
              transition: all 0.2s;
            }

            .btn-primary {
              background: var(--primary);
              color: #fff;
              border: 1px solid var(--primary);
            }

            .btn-primary:hover {
              box-shadow: 0 0 16px var(--primary-glow);
              transform: translateY(-1px);
            }

            /* Page Title & Stats */
            .page-header {
              padding: 48px 0 24px;
            }

            .hero-tag {
              display: inline-block;
              font-size: 0.8rem;
              text-transform: uppercase;
              letter-spacing: 0.08em;
              font-weight: 700;
              color: var(--accent);
              margin-bottom: 8px;
            }

            h1 {
              font-size: 2.5rem;
              font-weight: 800;
              letter-spacing: -0.02em;
              margin-bottom: 12px;
            }

            .subtitle {
              color: var(--text-muted);
              font-size: 1.1rem;
              max-width: 800px;
              margin-bottom: 32px;
            }

            .stats-grid {
              display: grid;
              grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
              gap: 16px;
              margin-bottom: 36px;
            }

            .stat-card {
              background: var(--card-bg);
              border: 1px solid var(--card-border);
              border-radius: 12px;
              padding: 20px;
              backdrop-filter: blur(12px);
            }

            .stat-num {
              font-size: 2rem;
              font-weight: 800;
              color: var(--text);
              margin-bottom: 4px;
            }

            .stat-label {
              font-size: 0.85rem;
              color: var(--text-muted);
              text-transform: uppercase;
              letter-spacing: 0.05em;
              font-weight: 600;
            }

            /* Filter & Search Toolbar */
            .toolbar {
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
            }

            .search-box {
              flex: 1;
              min-width: 260px;
              position: relative;
            }

            .search-box input {
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
            }

            .search-box input:focus {
              border-color: var(--primary);
            }

            .search-icon {
              position: absolute;
              left: 14px;
              top: 50%;
              transform: translateY(-50%);
              color: var(--text-muted);
              font-size: 1rem;
            }

            .filter-group {
              display: flex;
              flex-wrap: wrap;
              gap: 8px;
              align-items: center;
            }

            .filter-btn {
              background: rgba(255, 255, 255, 0.04);
              border: 1px solid var(--card-border);
              color: var(--text-muted);
              padding: 8px 14px;
              border-radius: 8px;
              font-size: 0.85rem;
              font-weight: 600;
              cursor: pointer;
              transition: all 0.2s;
            }

            .filter-btn:hover {
              background: rgba(255, 255, 255, 0.08);
              color: var(--text);
            }

            .filter-btn.active {
              background: var(--primary);
              border-color: var(--primary);
              color: #fff;
            }

            select.filter-select {
              background: rgba(0, 0, 0, 0.3);
              border: 1px solid var(--card-border);
              color: var(--text);
              padding: 8px 12px;
              border-radius: 8px;
              font-family: var(--font-sans);
              font-size: 0.85rem;
              outline: none;
              cursor: pointer;
            }

            /* Table Styles */
            .table-wrapper {
              background: var(--card-bg);
              border: 1px solid var(--card-border);
              border-radius: 12px;
              overflow-x: auto;
              margin-bottom: 48px;
            }

            table {
              width: 100%;
              border-collapse: collapse;
              text-align: left;
            }

            thead {
              background: rgba(0, 0, 0, 0.25);
              border-bottom: 1px solid var(--card-border);
            }

            th {
              padding: 14px 18px;
              font-size: 0.8rem;
              text-transform: uppercase;
              letter-spacing: 0.06em;
              color: var(--text-muted);
              font-weight: 700;
            }

            tbody tr {
              border-bottom: 1px solid rgba(255, 255, 255, 0.04);
              transition: background 0.15s;
            }

            tbody tr:hover {
              background: rgba(255, 255, 255, 0.02);
            }

            td {
              padding: 16px 18px;
              vertical-align: top;
              font-size: 0.9rem;
            }

            .game-title {
              font-weight: 700;
              font-size: 1rem;
              color: var(--text);
              margin-bottom: 2px;
            }

            .game-publisher {
              font-size: 0.8rem;
              color: var(--text-muted);
            }

            .link-steam {
              color: var(--accent);
              text-decoration: none;
            }

            .link-steam:hover {
              text-decoration: underline;
            }

            .link-source {
              color: var(--primary);
              text-decoration: none;
              font-family: var(--font-mono);
              font-size: 0.8rem;
            }

            .link-source:hover {
              text-decoration: underline;
            }

            /* Badges */
            .status-badge {
              display: inline-block;
              padding: 4px 10px;
              border-radius: 6px;
              font-size: 0.75rem;
              font-weight: 700;
              text-transform: uppercase;
              letter-spacing: 0.04em;
              white-space: nowrap;
            }

            .badge-native {
              background: rgba(16, 185, 129, 0.15);
              color: #34d399;
              border: 1px solid rgba(16, 185, 129, 0.3);
            }

            .badge-likely {
              background: rgba(59, 130, 246, 0.15);
              color: #60a5fa;
              border: 1px solid rgba(59, 130, 246, 0.3);
            }

            .badge-windows {
              background: rgba(245, 158, 11, 0.15);
              color: #fbbf24;
              border: 1px solid rgba(245, 158, 11, 0.3);
            }

            .badge-blocked {
              background: rgba(239, 68, 68, 0.15);
              color: #f87171;
              border: 1px solid rgba(239, 68, 68, 0.3);
            }

            .ac-badge {
              display: inline-block;
              font-size: 0.8rem;
              font-weight: 600;
            }

            .badge-ac-kernel {
              color: #f87171;
            }

            .badge-ac-userspace {
              color: #fbbf24;
            }

            .badge-ac-none {
              color: #34d399;
            }

            .ac-type {
              font-size: 0.75rem;
              color: var(--text-muted);
              margin-top: 2px;
            }

            .policy-badge {
              display: inline-block;
              padding: 3px 8px;
              border-radius: 4px;
              font-size: 0.75rem;
              font-weight: 600;
              white-space: nowrap;
            }

            .badge-policy-direct {
              background: rgba(16, 185, 129, 0.1);
              color: #34d399;
            }

            .badge-policy-offline {
              background: rgba(245, 158, 11, 0.1);
              color: #fbbf24;
            }

            .badge-policy-blocked {
              background: rgba(239, 68, 68, 0.1);
              color: #f87171;
            }

            code {
              font-family: var(--font-mono);
              font-size: 0.8rem;
              background: rgba(0, 0, 0, 0.4);
              padding: 2px 6px;
              border-radius: 4px;
              color: #e2e8f0;
            }

            .policy-notice-text {
              font-size: 0.8rem;
              color: #cbd5e1;
              line-height: 1.5;
              margin-bottom: 6px;
            }

            .sources-links {
              font-size: 0.75rem;
              color: var(--text-muted);
            }

            .no-results {
              padding: 48px;
              text-align: center;
              color: var(--text-muted);
              font-size: 1.1rem;
              display: none;
            }

            /* Footer */
            footer {
              border-top: 1px solid var(--card-border);
              padding: 36px 0;
              text-align: center;
              font-size: 0.85rem;
              color: var(--text-muted);
            }

            footer a {
              color: var(--text);
              text-decoration: none;
            }

            footer a:hover {
              text-decoration: underline;
            }
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
                  <div class="stat-num" id="stat-total">\(counts.total)</div>
                  <div class="stat-label">Profiles Cataloged</div>
                </div>
                <div class="stat-card">
                  <div class="stat-num" style="color: #34d399;" id="stat-verified">\(counts.verified)</div>
                  <div class="stat-label">Verified Confidence</div>
                </div>
                <div class="stat-card">
                  <div class="stat-num" style="color: #60a5fa;" id="stat-playable">\(counts.playableTotal)</div>
                  <div class="stat-label">Playable on Apple Silicon</div>
                </div>
                <div class="stat-card">
                  <div class="stat-num" style="color: #f87171;" id="stat-blocked">\(counts.blockedByAntiCheat)</div>
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
        \(rowsHtml)
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
            (function() {
              const searchInput = document.getElementById('search-input');
              const filterBtns = document.querySelectorAll('.filter-btn');
              const anticheatSelect = document.getElementById('anticheat-select');
              const rows = document.querySelectorAll('#matrix-tbody tr');
              const noResults = document.getElementById('no-results');

              let activeStatus = 'all';
              let activeAntiCheat = 'all';
              let searchQuery = '';

              function applyFilters() {
                let visibleCount = 0;
                rows.forEach(row => {
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

                  if (matchesSearch && matchesStatus && matchesAntiCheat) {
                    row.style.display = '';
                    visibleCount++;
                  } else {
                    row.style.display = 'none';
                  }
                });

                noResults.style.display = visibleCount === 0 ? 'block' : 'none';
              }

              searchInput.addEventListener('input', e => {
                searchQuery = e.target.value.toLowerCase().trim();
                applyFilters();
              });

              filterBtns.forEach(btn => {
                btn.addEventListener('click', () => {
                  filterBtns.forEach(b => b.classList.remove('active'));
                  btn.classList.add('active');
                  activeStatus = btn.getAttribute('data-filter');
                  applyFilters();
                });
              });

              anticheatSelect.addEventListener('change', e => {
                activeAntiCheat = e.target.value;
                applyFilters();
              });
            })();
          </script>
        </body>
        </html>
        """
    }

    public static func generateAndSave(
        profilesDirectory: URL,
        outputHtmlURL: URL
    ) throws -> (counts: BadgeCounts, html: String) {
        let repo = GameProfileRepository(customDirectory: profilesDirectory)
        let profiles = repo.allProfiles()
        let counts = calculateBadgeCounts(profiles: profiles)
        let html = generateHTML(profiles: profiles)

        let dir = outputHtmlURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try html.write(to: outputHtmlURL, atomically: true, encoding: .utf8)

        return (counts, html)
    }
}
