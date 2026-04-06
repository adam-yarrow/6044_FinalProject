function state = progressBar(i, n, t_start, state, name)
%PROGRESS_BAR  Waitbar with derivative-based ETA.
%   state = progress_bar(i, n, t_start, state)
%
%   First call (i==1): pass state = [] to initialise.
%   Returns updated state — assign it back each iteration.
%   Closes the waitbar automatically when i == n.

% MADE BY CLAUDE.AI

  WINDOW = 20;

  now = toc(t_start);

  if nargin < 5
      name = 'Progress';
  end

  %% ── initialise on first call ────────────────────────────────────────────
  if isempty(state)
    state.times  = zeros(1, WINDOW);
    state.head   = 0;
    state.count  = 0;
    state.t_prev = now;
    state.wb     = waitbar(0, 'Starting...', ...
                     'Name', name, ...
                     'CreateCancelBtn', 'setappdata(gcbf,''cancelling'',1)');
    setappdata(state.wb, 'cancelling', 0);
    return
  end

  %% ── check for cancel ────────────────────────────────────────────────────
  if getappdata(state.wb, 'cancelling')
    delete(state.wb);
    state.wb = [];
    state.cancelled = true;
    return
  end
  state.cancelled = false;

  %% ── record iteration duration ───────────────────────────────────────────
  dt           = now - state.t_prev;
  state.t_prev = now;
  state.head   = mod(state.head, WINDOW) + 1;
  state.times(state.head) = dt;
  state.count  = min(state.count + 1, WINDOW);

  %% ── weighted moving average (newest = highest weight) ───────────────────
  idx    = mod(state.head - (state.count-1 : -1 : 0) - 1, WINDOW) + 1;
  dts    = state.times(idx);
  w      = 1 : state.count;
  dt_est = dot(w, dts) / sum(w);
  eta_s  = dt_est * (n - i);

  %% ── format label ────────────────────────────────────────────────────────
  if eta_s < 60
    eta_str = sprintf('%.1fs', eta_s);
  elseif eta_s < 3600
    eta_str = sprintf('%dm %02ds', floor(eta_s/60), mod(round(eta_s),60));
  else
    eta_str = sprintf('%dh %02dm', floor(eta_s/3600), mod(floor(eta_s/60),60));
  end

  msg = sprintf('Iter %d / %d   elapsed %.1fs   ETA %s', ...
          i, n, now, eta_str);

  %% ── update or close waitbar ─────────────────────────────────────────────
  if i < n
    waitbar(i/n, state.wb, msg);
  else
    waitbar(1, state.wb, sprintf('Done — %.2fs total', now));
    pause(0.8);
    delete(state.wb);
    state.wb = [];
  end
end