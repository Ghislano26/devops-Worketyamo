/*
 * git-graph.js — mini moteur Git avec rendu SVG animé
 * ----------------------------------------------------
 * Aucune dépendance externe : à charger avec une balise <script> classique.
 *
 * Contenu du fichier :
 *   1. Modèle  (Repo)      : commits, branches, HEAD et commandes git fictives.
 *   2. Mise en page        : calcule la position (x, y) de chaque commit.
 *   3. Rendu   (Renderer)  : dessine le graphe en SVG et l'anime (CSS).
 *   4. Interface           : console, boutons, objectif, succès, mode démo.
 *
 * Utilisation (voir exercices/*.html) :
 *   GitGraph.exercise({ mount: '#app', id: '...', initial: {...}, check: function (repo) {...} });
 */
(function (global) {
  'use strict';

  /* ================================================================
   * 1. MODÈLE : un dépôt Git simplifié
   * ================================================================ */

  /** Découpe une ligne de commande en mots, en respectant les guillemets. */
  function tokenize(line) {
    if ((line.match(/"/g) || []).length % 2) {
      throw new Error('Guillemets non fermés dans la commande.');
    }
    var re = /"([^"]*)"|'([^']*)'|(\S+)/g, out = [], m;
    while ((m = re.exec(line))) {
      out.push(m[1] !== undefined ? m[1] : (m[2] !== undefined ? m[2] : m[3]));
    }
    return out;
  }

  /**
   * Un dépôt : { commits: {id: {id, parents, msg, n}}, branches: {nom: id}, head }
   *  - n    : numéro de création (sert à ordonner et à placer les commits) ;
   *  - head : { branch: 'main' } (rattaché) ou { commit: 'C2' } (détaché).
   */
  function Repo(spec) {
    this.load(spec);
  }

  /** (Ré)initialise le dépôt à partir d'un état initial décrit dans l'exercice. */
  Repo.prototype.load = function (spec) {
    var self = this;
    this.commits = {};
    this.branches = {};
    this.counter = 0;
    (spec.commits || []).forEach(function (c) { self._add(c.id, c.parents || [], c.msg || c.id); });
    Object.keys(spec.branches || {}).forEach(function (b) { self.branches[b] = spec.branches[b]; });
    this.head = spec.detached ? { commit: spec.detached } : { branch: spec.head || 'main' };
  };

  Repo.prototype._add = function (id, parents, msg) {
    this.counter += 1;
    this.commits[id] = { id: id, parents: parents, msg: msg, n: this.counter };
    return this.commits[id];
  };

  /** Prochain identifiant libre : C1, C2, ... (les copies reçoivent une apostrophe : C3'). */
  Repo.prototype.nextId = function () {
    var max = 0;
    Object.keys(this.commits).forEach(function (k) {
      var v = parseInt(k.replace(/[^0-9]/g, ''), 10);
      if (v > max) { max = v; }
    });
    return 'C' + (max + 1);
  };

  Repo.prototype.copyId = function (id) {
    var nid = id + "'";
    while (this.commits[nid]) { nid += "'"; }
    return nid;
  };

  Repo.prototype.headCommit = function () {
    return this.head.branch ? this.branches[this.head.branch] : this.head.commit;
  };

  /** Déplace la branche courante (ou HEAD s'il est détaché) vers un commit. */
  Repo.prototype.moveHead = function (id) {
    if (this.head.branch) { this.branches[this.head.branch] = id; } else { this.head.commit = id; }
  };

  /** Ensemble des ancêtres d'un commit, lui-même inclus. */
  Repo.prototype.ancestors = function (id) {
    var seen = {}, stack = [id], self = this;
    while (stack.length) {
      var x = stack.pop();
      if (!x || seen[x] || !self.commits[x]) { continue; }
      seen[x] = true;
      self.commits[x].parents.forEach(function (p) { stack.push(p); });
    }
    return seen;
  };

  /** Ancêtre commun le plus récent de deux commits (la « merge base »). */
  Repo.prototype.mergeBase = function (a, b) {
    var sa = this.ancestors(a), sb = this.ancestors(b), best = null, self = this;
    Object.keys(sa).forEach(function (id) {
      if (sb[id] && (!best || self.commits[id].n > self.commits[best].n)) { best = id; }
    });
    return best;
  };

  /** Commits atteignables depuis une branche ou HEAD (les autres sont « orphelins »). */
  Repo.prototype.reachable = function () {
    var out = {}, self = this;
    var tips = Object.keys(this.branches).map(function (b) { return self.branches[b]; });
    tips.push(this.headCommit());
    tips.forEach(function (t) {
      var a = self.ancestors(t);
      Object.keys(a).forEach(function (k) { out[k] = true; });
    });
    return out;
  };

  /** Pointeur d'une branche vers son commit (null si la branche n'existe pas). */
  Repo.prototype.tip = function (name) {
    return this.branches[name] || null;
  };

  /** Parent n°i (0 par défaut) d'un commit, ou null. */
  Repo.prototype.parentOf = function (id, i) {
    var c = this.commits[id];
    return c && c.parents[i || 0] ? c.parents[i || 0] : null;
  };

  /** Convertit « HEAD~2 », « main », « c3 », « bugfix^ » en identifiant de commit (ou null). */
  Repo.prototype.resolve = function (ref) {
    var self = this;
    var suffix = /((?:~\d*|\^)+)$/.exec(ref);
    var base = suffix ? ref.slice(0, ref.length - suffix[1].length) : ref;
    var id = null;
    if (base === 'HEAD') {
      id = this.headCommit();
    } else if (this.branches[base]) {
      id = this.branches[base];
    } else {
      Object.keys(this.commits).forEach(function (k) { if (k.toLowerCase() === base.toLowerCase()) { id = k; } });
    }
    if (id && suffix) {
      (suffix[1].match(/~\d*|\^/g) || []).forEach(function (s) {
        var n = s === '^' ? 1 : (s.length > 1 ? parseInt(s.slice(1), 10) : 1);
        for (var i = 0; i < n && id; i++) { id = self.parentOf(id, 0); }
      });
    }
    return id;
  };

  Repo.prototype._need = function (ref) {
    var id = this.resolve(ref);
    if (!id) { throw new Error("Référence inconnue : « " + ref + " ». Branches et commits connus : " + this._names() + '.'); }
    return id;
  };

  Repo.prototype._names = function () {
    return Object.keys(this.branches).concat(Object.keys(this.commits)).join(', ');
  };

  Repo.prototype._where = function () {
    return this.head.branch ? 'branche ' + this.head.branch : 'HEAD détaché';
  };

  Repo.prototype._checkName = function (name) {
    if (!name || !/^[A-Za-z0-9._\/-]+$/.test(name)) {
      throw new Error("Nom de branche invalide : « " + (name || '') + " » (lettres, chiffres, . _ - / uniquement).");
    }
  };

  /* ---------- Commandes ---------- */

  Repo.prototype.commit = function (msg) {
    var parent = this.headCommit(), id = this.nextId();
    this._add(id, [parent], msg);
    this.moveHead(id);
    return ['[' + (this.head.branch || 'HEAD détaché') + ' ' + id + '] ' + msg];
  };

  Repo.prototype.branch = function (name, start) {
    this._checkName(name);
    if (this.branches[name]) { throw new Error("La branche « " + name + " » existe déjà."); }
    this.branches[name] = start ? this._need(start) : this.headCommit();
    return ["Branche « " + name + " » créée sur " + this.branches[name] + ". (HEAD n'a pas bougé : utilisez git switch " + name + ")"];
  };

  Repo.prototype.deleteBranch = function (name, force) {
    if (!this.branches[name]) { throw new Error("La branche « " + name + " » n'existe pas."); }
    if (this.head.branch === name) { throw new Error("Impossible de supprimer la branche courante « " + name + " »."); }
    if (!force && !this.ancestors(this.headCommit())[this.branches[name]]) {
      throw new Error("La branche « " + name + " » n'est pas fusionnée. Utilisez -D pour forcer (ses commits deviendront orphelins).");
    }
    delete this.branches[name];
    return ["Branche « " + name + " » supprimée (seul le pointeur disparaît, pas les commits)."];
  };

  Repo.prototype.listBranches = function () {
    var self = this;
    return Object.keys(this.branches).sort().map(function (b) {
      return (self.head.branch === b ? '* ' : '  ') + b + '  → ' + self.branches[b];
    }).concat(this.head.branch ? [] : ['* (HEAD détaché sur ' + this.head.commit + ')']);
  };

  Repo.prototype.switchTo = function (name, create) {
    if (create) {
      this.branch(name);
      this.head = { branch: name };
      return ["Nouvelle branche « " + name + " » créée et activée."];
    }
    if (!this.branches[name]) {
      throw new Error("Branche inconnue : « " + name + " ». Pour la créer : git switch -c " + name);
    }
    this.head = { branch: name };
    return ["Basculé sur la branche « " + name + " »."];
  };

  Repo.prototype.detach = function (ref) {
    var id = this._need(ref);
    this.head = { commit: id };
    return ["HEAD détaché sur " + id + ". Créez une branche (git switch -c nom) avant de committer pour ne rien perdre."];
  };

  Repo.prototype.checkout = function (target, create) {
    if (create) { return this.switchTo(target, true); }
    if (this.branches[target]) { return this.switchTo(target, false); }
    return this.detach(target);
  };

  Repo.prototype.merge = function (ref) {
    var target = this._need(ref), cur = this.headCommit();
    if (this.ancestors(cur)[target]) { return ['Déjà à jour : ' + ref + ' est déjà contenu dans ' + this._where() + '.']; }
    if (this.ancestors(target)[cur]) {
      this.moveHead(target);
      return ['Fast-forward : le pointeur avance jusqu\'à ' + target + ' (aucun nouveau commit).'];
    }
    var id = this.nextId();
    this._add(id, [cur, target], 'Fusion de ' + ref);
    this.moveHead(id);
    return ['Fusion à trois points : nouveau commit ' + id + ' à deux parents (' + cur + ' et ' + target + ').'];
  };

  Repo.prototype.rebase = function (ref) {
    if (!this.head.branch) { throw new Error('Le rebase nécessite d\'être sur une branche (HEAD est détaché).'); }
    var onto = this._need(ref), cur = this.headCommit(), self = this;
    if (this.ancestors(onto)[cur]) {
      this.moveHead(onto);
      return ['Fast-forward : ' + this.head.branch + ' avance jusqu\'à ' + onto + '.'];
    }
    if (this.ancestors(cur)[onto]) { return ['Déjà à jour : rien à rejouer.']; }
    var inOnto = this.ancestors(onto), mine = this.ancestors(cur);
    var toReplay = Object.keys(mine).filter(function (id) { return !inOnto[id]; })
      .sort(function (a, b) { return self.commits[a].n - self.commits[b].n; });
    var parent = onto, mapping = [];
    toReplay.forEach(function (id) {
      var nid = self.copyId(id);
      self._add(nid, [parent], self.commits[id].msg);
      mapping.push(id + ' → ' + nid);
      parent = nid;
    });
    this.moveHead(parent);
    return ['Rebase terminé : ' + toReplay.length + ' commit(s) rejoué(s) sur ' + onto + ' (' + mapping.join(', ') +
      '). Les anciens commits deviennent orphelins : leur empreinte a changé.'];
  };

  Repo.prototype.cherryPick = function (refs) {
    var self = this, out = [];
    if (!refs.length) { throw new Error('Précisez au moins un commit : git cherry-pick C3'); }
    refs.forEach(function (r) {
      var id = self._need(r);
      if (self.commits[id].parents.length > 1) { throw new Error(id + ' est un commit de fusion : non géré dans cette démo.'); }
      var nid = self.copyId(id);
      self._add(nid, [self.headCommit()], self.commits[id].msg);
      self.moveHead(nid);
      out.push(id + ' copié sur ' + self._where() + ' → nouveau commit ' + nid + ' (nouvelle empreinte).');
    });
    return out;
  };

  Repo.prototype.resetHard = function (ref) {
    var id = this._need(ref);
    this.moveHead(id);
    return [this._where().replace(/^./, function (c) { return c.toUpperCase(); }) + ' pointe maintenant sur ' + id +
      '. Les commits plus atteignables apparaissent en pointillés (le reflog les retient).'];
  };

  Repo.prototype.log = function () {
    var self = this, anc = this.ancestors(this.headCommit());
    return Object.keys(anc).sort(function (a, b) { return self.commits[b].n - self.commits[a].n; }).map(function (id) {
      var deco = Object.keys(self.branches).filter(function (b) { return self.branches[b] === id; });
      if (self.headCommit() === id) { deco.unshift(self.head.branch ? 'HEAD -> ' + self.head.branch : 'HEAD'); }
      var parents = self.commits[id].parents.join('+');
      return id + (deco.length ? ' (' + deco.join(', ') + ')' : '') + '  ' + self.commits[id].msg + (parents ? '  [parent : ' + parents + ']' : '  [racine]');
    });
  };

  Repo.prototype.status = function () {
    return [this.head.branch ? 'Sur la branche ' + this.head.branch + ' (commit ' + this.headCommit() + ').' :
      'HEAD détaché sur ' + this.head.commit + '.'];
  };

  var AIDE = [
    'Commandes disponibles :',
    '  git commit -m "message"        crée un commit sur la branche courante',
    '  git branch <nom>               crée une branche (sans s\'y déplacer) ; sans argument : liste',
    '  git branch -d <nom>            supprime une branche fusionnée (-D pour forcer)',
    '  git switch <nom>               change de branche (-c pour créer, --detach <réf> pour détacher HEAD)',
    '  git checkout <nom|commit>      idem (checkout -b <nom> pour créer)',
    '  git merge <nom>                fusionne <nom> dans la branche courante',
    '  git rebase <nom>               rejoue les commits de la branche courante sur <nom>',
    '  git cherry-pick <commit>...    copie un ou plusieurs commits sur la branche courante',
    '  git reset --hard <réf>         déplace la branche courante (et l\'état) vers <réf>',
    '  git log, git status            informations',
    '  reset                          remet l\'exercice à zéro',
    '  hint / solution                indice / solution de l\'exercice',
    'Références acceptées : nom de branche, identifiant (C3), HEAD, HEAD~2, main^ ...'
  ];

  /** Exécute une ligne « git ... » et renvoie la liste des lignes de réponse (ou lève une Error). */
  Repo.prototype.run = function (line) {
    var t = tokenize(line.trim());
    if (!t.length) { return []; }
    if (t[0] !== 'git') {
      throw new Error('Commande inconnue : « ' + t[0] + ' ». Les commandes Git commencent par « git ». Tapez help.');
    }
    var sub = t[1], a = t.slice(2), i;
    switch (sub) {
      case 'commit':
        i = Math.max(a.indexOf('-m'), a.indexOf('-am'));
        if (i < 0 || !a[i + 1]) { throw new Error('Message requis : git commit -m "mon message"'); }
        return this.commit(a[i + 1]);
      case 'branch':
        if (!a.length) { return this.listBranches(); }
        if (a[0] === '-d' || a[0] === '-D') { return this.deleteBranch(a[1], a[0] === '-D'); }
        return this.branch(a[0], a[1]);
      case 'switch':
        if (a[0] === '-c') { return this.switchTo(a[1], true); }
        if (a[0] === '--detach') { return this.detach(a[1]); }
        if (!a[0]) { throw new Error('Précisez une branche : git switch <nom>'); }
        if (!this.branches[a[0]] && this.resolve(a[0])) {
          throw new Error("git switch attend une branche. Pour aller sur un commit : git switch --detach " + a[0]);
        }
        return this.switchTo(a[0], false);
      case 'checkout':
        if (a[0] === '-b') { return this.checkout(a[1], true); }
        if (!a[0]) { throw new Error('Précisez une branche ou un commit : git checkout <nom|commit>'); }
        return this.checkout(a[0], false);
      case 'merge':
        if (!a[0]) { throw new Error('Précisez la branche à fusionner : git merge <nom>'); }
        return this.merge(a[0]);
      case 'rebase':
        if (!a[0]) { throw new Error('Précisez la base : git rebase <nom>'); }
        return this.rebase(a[0]);
      case 'cherry-pick':
        return this.cherryPick(a);
      case 'reset':
        if (a.indexOf('--hard') < 0) { throw new Error('Cette démo ne gère que « git reset --hard <réf> ».'); }
        return this.resetHard(a.filter(function (x) { return x !== '--hard'; })[0] || 'HEAD');
      case 'log': return this.log();
      case 'status': return this.status();
      case undefined: throw new Error('Précisez une sous-commande. Tapez help.');
      default:
        throw new Error('Sous-commande non gérée : « git ' + sub + ' ». Tapez help pour la liste.');
    }
  };

  /* ================================================================
   * 2. MISE EN PAGE : position de chaque commit
   *    x = profondeur dans le graphe ; y = « voie » (lane).
   *    Le premier enfant d'un commit reste sur sa voie, les autres ouvrent une nouvelle voie.
   * ================================================================ */
  var DX = 104, DY = 96, R = 20, PAD_L = 56, PAD_T = 122;

  function layout(repo) {
    var ids = Object.keys(repo.commits).sort(function (a, b) { return repo.commits[a].n - repo.commits[b].n; });
    var depth = {}, lane = {}, taken = {}, next = 1, pos = {}, maxD = 0, maxL = 0;
    function d(id) {
      if (depth[id] !== undefined) { return depth[id]; }
      var v = 0;
      repo.commits[id].parents.forEach(function (p) { v = Math.max(v, d(p) + 1); });
      depth[id] = v;
      return v;
    }
    ids.forEach(function (id) {
      d(id);
      var p = repo.commits[id].parents[0];
      if (p === undefined) { lane[id] = 0; }
      else if (!taken[p]) { taken[p] = true; lane[id] = lane[p]; }
      else { lane[id] = next++; }
      pos[id] = { x: PAD_L + depth[id] * DX, y: PAD_T + lane[id] * DY };
      maxD = Math.max(maxD, depth[id]);
      maxL = Math.max(maxL, lane[id]);
    });
    return { pos: pos, width: PAD_L * 2 + maxD * DX + 40, height: PAD_T + maxL * DY + 64 };
  }

  /* ================================================================
   * 3. RENDU SVG + ANIMATIONS (les animations elles-mêmes sont dans style.css)
   * ================================================================ */
  var NS = 'http://www.w3.org/2000/svg';
  var PALETTE = [
    ['#bfdbfe', '#1e3a8a'], ['#bbf7d0', '#14532d'], ['#fde68a', '#78350f'],
    ['#fbcfe8', '#831843'], ['#ddd6fe', '#4c1d95'], ['#fecaca', '#7f1d1d'], ['#a5f3fc', '#164e63']
  ];

  function svgEl(name, attrs, parent) {
    var e = document.createElementNS(NS, name);
    Object.keys(attrs || {}).forEach(function (k) { e.setAttribute(k, attrs[k]); });
    if (parent) { parent.appendChild(e); }
    return e;
  }

  /** Une couleur stable par nom de branche (main est toujours bleu). */
  function colorFor(name) {
    if (name === 'main') { return PALETTE[0]; }
    var h = 0, i;
    for (i = 0; i < name.length; i++) { h = (h * 31 + name.charCodeAt(i)) >>> 0; }
    return PALETTE[1 + (h % (PALETTE.length - 1))];
  }

  function Renderer(container) {
    this.container = container;
    this.reset();
  }

  /** Efface tout et recrée un SVG vide (utilisé au démarrage et à la réinitialisation). */
  Renderer.prototype.reset = function () {
    this.container.textContent = '';
    this.svg = svgEl('svg', { 'class': 'gg-svg', role: 'img', 'aria-label': 'Graphe des commits' });
    var defs = svgEl('defs', {}, this.svg);
    var marker = svgEl('marker', { id: 'gg-arrow', viewBox: '0 0 10 10', refX: '9', refY: '5', markerWidth: '7', markerHeight: '7', orient: 'auto' }, defs);
    svgEl('path', { d: 'M0 0 L10 5 L0 10 z', 'class': 'gg-arrowhead' }, marker);
    this.gEdges = svgEl('g', {}, this.svg);
    this.gCommits = svgEl('g', {}, this.svg);
    this.gLabels = svgEl('g', {}, this.svg);
    this.container.appendChild(this.svg);
    this.commits = {}; this.edges = {}; this.labels = {};
    this.count = 0;
  };

  /** Réconcilie le DOM avec l'état du dépôt : crée ce qui manque (avec animation), déplace le reste. */
  Renderer.prototype.render = function (repo) {
    var self = this, L = layout(repo), reach = repo.reachable(), headId = repo.headCommit();
    this.svg.setAttribute('width', L.width);
    this.svg.setAttribute('height', L.height);
    this.svg.setAttribute('viewBox', '0 0 ' + L.width + ' ' + L.height);

    /* --- Commits (cercles) --- */
    Object.keys(repo.commits).forEach(function (id) {
      var c = repo.commits[id], p = L.pos[id], g = self.commits[id];
      if (!g) {
        g = svgEl('g', { 'class': 'gg-commit' }, self.gCommits);
        var inner = svgEl('g', { 'class': 'gg-pop' }, g);
        inner.style.animationDelay = (self.count++ * 70) + 'ms';
        inner.addEventListener('animationend', function () { inner.classList.remove('gg-pop'); inner.style.animationDelay = ''; });
        svgEl('circle', { r: R, cx: 0, cy: 0 }, inner);
        var t = svgEl('text', { 'class': 'gg-id', 'text-anchor': 'middle', y: 5 }, inner);
        t.textContent = id;
        var m = svgEl('text', { 'class': 'gg-msg', 'text-anchor': 'middle', y: R + 18 }, inner);
        m.textContent = c.msg.length > 15 ? c.msg.slice(0, 14) + '…' : c.msg;
        var ti = svgEl('title', {}, g);
        ti.textContent = id + ' — ' + c.msg;
        self.commits[id] = g;
      }
      g.style.transform = 'translate(' + p.x + 'px,' + p.y + 'px)';
      g.classList.toggle('gg-orphan', !reach[id]);
      g.classList.toggle('gg-head-commit', id === headId);
    });

    /* --- Arêtes enfant → parent (flèches) --- */
    Object.keys(repo.commits).forEach(function (id) {
      repo.commits[id].parents.forEach(function (pid, i) {
        var key = id + '>' + pid, a = L.pos[id], b = L.pos[pid], e = self.edges[key];
        var sx = a.x - R, sy = a.y, ex = b.x + R + 2, ey = b.y, dx = Math.max(24, (sx - ex) / 2);
        var d = 'M' + sx + ' ' + sy + ' C' + (sx - dx) + ' ' + sy + ' ' + (ex + dx) + ' ' + ey + ' ' + ex + ' ' + ey;
        var isNew = !e;
        if (!e) {
          e = svgEl('path', { 'class': 'gg-edge' + (i > 0 ? ' gg-second' : ''), 'marker-end': 'url(#gg-arrow)' }, self.gEdges);
          self.edges[key] = e;
        }
        e.setAttribute('d', d);
        e.classList.toggle('gg-orphan', !reach[id]);
        if (isNew) {
          var len = 120;
          try { len = Math.ceil(e.getTotalLength()) + 2; } catch (err) { /* SVG non rendu */ }
          e.style.setProperty('--len', len);
          e.classList.add('gg-draw');
          e.addEventListener('animationend', function () { e.classList.remove('gg-draw'); });
        }
      });
    });

    /* --- Étiquettes : branches (rectangles colorés) et HEAD --- */
    var wanted = {}, stack = {};
    Object.keys(repo.branches).sort(function (x, y) {
      return (y === repo.head.branch) - (x === repo.head.branch) || (x < y ? -1 : 1);
    }).forEach(function (b) {
      var cid = repo.branches[b];
      stack[cid] = stack[cid] || 0;
      wanted['b:' + b] = { text: (repo.head.branch === b ? 'HEAD → ' : '') + b, commit: cid, index: stack[cid]++, color: colorFor(b), current: repo.head.branch === b };
    });
    if (!repo.head.branch) {
      stack[repo.head.commit] = stack[repo.head.commit] || 0;
      wanted['#head'] = { text: 'HEAD', commit: repo.head.commit, index: stack[repo.head.commit]++, color: ['#fecaca', '#7f1d1d'], current: true, detached: true };
    }
    Object.keys(this.labels).forEach(function (k) {
      if (!wanted[k]) { self.labels[k].parentNode.removeChild(self.labels[k]); delete self.labels[k]; }
    });
    Object.keys(wanted).forEach(function (k) {
      var w = wanted[k], g = self.labels[k], width = Math.round(w.text.length * 7.6 + 20), p = L.pos[w.commit];
      if (!g) {
        g = svgEl('g', { 'class': 'gg-label' }, self.gLabels);
        var inner = svgEl('g', { 'class': 'gg-pop' }, g);
        inner.addEventListener('animationend', function () { inner.classList.remove('gg-pop'); });
        svgEl('rect', { height: 24, rx: 6, y: 0 }, inner);
        svgEl('text', { y: 16, 'text-anchor': 'middle' }, inner);
        g._inner = inner;
        self.labels[k] = g;
      }
      var rect = g._inner.querySelector('rect'), text = g._inner.querySelector('text');
      rect.setAttribute('width', width);
      rect.setAttribute('x', -width / 2);
      rect.style.fill = w.color[0];
      text.style.fill = w.color[1];
      text.textContent = w.text;
      g.classList.toggle('gg-current', !!w.current);
      g.classList.toggle('gg-detached', !!w.detached);
      g.style.transform = 'translate(' + p.x + 'px,' + (p.y - R - 14 - 24 - w.index * 28) + 'px)';
    });

    /* Fait défiler vers le commit courant pour que l'animation reste visible. */
    var hp = L.pos[headId];
    if (hp && this.container.scrollWidth > this.container.clientWidth) {
      this.container.scrollLeft = Math.max(0, hp.x - this.container.clientWidth / 2);
    }
  };

  /* ================================================================
   * 4. INTERFACE : console, objectif, indices, succès, mode démo
   * ================================================================ */

  function h(tag, attrs, children) {
    var e = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === 'text') { e.textContent = attrs[k]; } else if (k === 'html') { e.innerHTML = attrs[k]; } else { e.setAttribute(k, attrs[k]); }
    });
    (children || []).forEach(function (c) { e.appendChild(c); });
    return e;
  }

  /**
   * Construit un exercice complet.
   * cfg = { mount, id, initial, goal: {html}, check(repo), hints[], solution[], demo[], next: {href, label} }
   */
  function exercise(cfg) {
    var root = typeof cfg.mount === 'string' ? document.querySelector(cfg.mount) : cfg.mount;
    var repo = new Repo(cfg.initial);
    var state = { solved: false, count: 0, hint: 0, history: [], hpos: 0, timer: null, demo: false };
    var autoplay = /[?&]autoplay=1/.test(global.location ? global.location.search : '');

    /* ---- Construction de la page ---- */
    var status = h('p', { 'class': 'gg-status', text: '⏳ À faire' });
    var goal = h('section', { 'class': 'gg-goal', 'aria-label': 'Objectif' }, [
      h('h2', { text: '🎯 Objectif' }),
      h('div', { html: cfg.goal.html }),
      status
    ]);
    var graph = h('div', { 'class': 'gg-graph', tabindex: '0', 'aria-label': 'Graphe des commits (défilable)' });
    var btnHint = h('button', { type: 'button', 'class': 'gg-btn', text: '💡 Indice' });
    var btnSol = h('button', { type: 'button', 'class': 'gg-btn', text: '🧩 Solution' });
    var btnReset = h('button', { type: 'button', 'class': 'gg-btn', text: '↺ Réinitialiser' });
    var btnDemo = h('button', { type: 'button', 'class': 'gg-btn', text: '▶ Démo animée' });
    var toolbar = h('div', { 'class': 'gg-toolbar' }, [btnHint, btnSol, btnReset, btnDemo]);
    var banner = h('p', { 'class': 'gg-banner', hidden: '' });
    var out = h('div', { 'class': 'gg-output', role: 'log', 'aria-live': 'polite', tabindex: '0', 'aria-label': 'Sortie de la console' });
    var input = h('input', { id: 'gg-input-' + cfg.id, 'class': 'gg-input', type: 'text', autocomplete: 'off', spellcheck: 'false', autocapitalize: 'off', placeholder: 'git commit -m "mon message"' });
    var form = h('form', { 'class': 'gg-form' }, [
      h('label', { 'for': input.id, 'class': 'gg-label-input', text: 'Commande' }),
      h('span', { 'class': 'gg-prompt', 'aria-hidden': 'true', text: '$' }),
      input,
      h('button', { type: 'submit', 'class': 'gg-btn gg-primary', text: 'Exécuter' })
    ]);
    var success = h('div', { 'class': 'gg-success', role: 'status', hidden: '' });
    root.appendChild(goal);
    root.appendChild(banner);
    root.appendChild(graph);
    root.appendChild(success);
    root.appendChild(toolbar);
    root.appendChild(h('div', { 'class': 'gg-console' }, [out, form]));
    var renderer = new Renderer(graph);

    /* ---- Console ---- */
    function print(text, cls) {
      out.appendChild(h('div', { 'class': 'gg-line ' + (cls || ''), text: text }));
      out.scrollTop = out.scrollHeight;
    }
    function printMany(lines, cls) { lines.forEach(function (l) { print(l, cls); }); }

    function redraw() { renderer.render(repo); }

    function showSuccess() {
      state.solved = true;
      status.textContent = '✅ Réussi !';
      status.classList.add('gg-ok');
      try { global.localStorage.setItem('gitgraph:' + cfg.id, '1'); } catch (e) { /* stockage indisponible */ }
      var min = (cfg.solution || []).length;
      success.textContent = '';
      var svg = svgEl('svg', { viewBox: '0 0 52 52', 'class': 'gg-check', 'aria-hidden': 'true' });
      var c1 = svgEl('circle', { cx: 26, cy: 26, r: 24, 'class': 'gg-check-circle' }, svg);
      var c2 = svgEl('path', { d: 'M14 27 L23 36 L39 17', 'class': 'gg-check-mark' }, svg);
      c1.style.setProperty('--len', 151); c2.style.setProperty('--len', 40);
      success.appendChild(svg);
      success.appendChild(h('p', { 'class': 'gg-success-title', text: 'Bravo, objectif atteint !' }));
      success.appendChild(h('p', { text: 'Résolu en ' + state.count + ' commande(s)' + (min ? ' (solution de référence : ' + min + ').' : '.') }));
      var links = h('p', { 'class': 'gg-success-links' });
      if (!state.demo) {
        var again = h('button', { type: 'button', 'class': 'gg-btn', text: '↺ Rejouer' });
        again.addEventListener('click', resetAll);
        links.appendChild(again);
        if (cfg.next) { links.appendChild(h('a', { 'class': 'gg-btn gg-primary', href: cfg.next.href, text: cfg.next.label })); }
      }
      success.appendChild(links);
      success.hidden = false;
      success.classList.remove('gg-success-in'); void success.offsetWidth; success.classList.add('gg-success-in');
      print('✔ Objectif atteint !', 'gg-good');
    }

    function check() {
      var ok = false;
      try { ok = !!cfg.check(repo); } catch (e) { ok = false; }
      if (ok && !state.solved) { showSuccess(); }
    }

    function resetAll() {
      repo.load(cfg.initial);
      renderer.reset();
      redraw();
      out.textContent = '';
      state.solved = false; state.count = 0; state.hint = 0;
      status.textContent = '⏳ À faire'; status.classList.remove('gg-ok');
      success.hidden = true;
      print('Exercice réinitialisé. Tapez help pour la liste des commandes.', 'gg-info');
    }

    /** Exécute une commande saisie (ou rejouée par la démo). */
    function submit(line) {
      line = line.trim();
      if (!line) { return; }
      print('$ ' + line, 'gg-cmd');
      var w = line.split(/\s+/)[0];
      if (w === 'reset' && line.split(/\s+/).length === 1) { resetAll(); return; }
      if (line === 'help' || line === 'aide') { printMany(AIDE, 'gg-info'); return; }
      if (line === 'clear') { out.textContent = ''; return; }
      if (line === 'hint' || line === 'indice') { showHint(); return; }
      if (line === 'solution') { showSolution(); return; }
      try {
        var res = repo.run(line);
        state.count += 1;
        printMany(res, 'gg-out');
        redraw();
        check();
      } catch (e) {
        print('✘ ' + e.message, 'gg-err');
      }
    }

    function showHint() {
      var hs = cfg.hints || [];
      if (!hs.length) { print('Pas d\'indice pour cet exercice.', 'gg-info'); return; }
      print('💡 Indice ' + (state.hint + 1) + '/' + hs.length + ' : ' + hs[Math.min(state.hint, hs.length - 1)], 'gg-info');
      state.hint = Math.min(state.hint + 1, hs.length);
    }

    function showSolution() {
      print('🧩 Solution possible (essayez d\'abord de comprendre pourquoi elle fonctionne) :', 'gg-info');
      (cfg.solution || []).forEach(function (s) { print('   ' + s, 'gg-info'); });
    }

    /* ---- Mode démo : tape et exécute les commandes automatiquement, en boucle ---- */
    function stopDemo() {
      if (!state.demo) { return; }
      state.demo = false;
      clearTimeout(state.timer);
      banner.hidden = true;
      btnDemo.textContent = '▶ Démo animée';
      input.value = '';
    }

    function startDemo() {
      var cmds = cfg.demo || cfg.solution || [];
      if (!cmds.length) { return; }
      stopDemo();
      resetAll();
      state.demo = true;
      banner.hidden = false;
      banner.textContent = '▶ Mode démo : les commandes sont rejouées en boucle. Appuyez sur une touche ou cliquez sur « Arrêter » pour reprendre la main.';
      btnDemo.textContent = '■ Arrêter la démo';
      var i = 0;
      function typeNext() {
        if (!state.demo) { return; }
        if (i >= cmds.length) {
          state.timer = setTimeout(function () { if (state.demo) { resetAll(); i = 0; state.timer = setTimeout(typeNext, 900); } }, 3800);
          return;
        }
        var text = cmds[i], k = 0;
        input.value = '';
        (function typeChar() {
          if (!state.demo) { return; }
          if (k <= text.length) {
            input.value = text.slice(0, k++);
            state.timer = setTimeout(typeChar, 32);
          } else {
            state.timer = setTimeout(function () {
              if (!state.demo) { return; }
              input.value = '';
              submit(text);
              i += 1;
              state.timer = setTimeout(typeNext, 1500);
            }, 350);
          }
        })();
      }
      typeNext();
    }

    /* ---- Événements ---- */
    form.addEventListener('submit', function (ev) {
      ev.preventDefault();
      stopDemo();
      var v = input.value;
      if (v.trim()) { state.history.push(v); state.hpos = state.history.length; }
      input.value = '';
      submit(v);
    });
    input.addEventListener('keydown', function (ev) {
      if (state.demo) { stopDemo(); return; }
      if (ev.key === 'ArrowUp' && state.history.length) {
        state.hpos = Math.max(0, state.hpos - 1); input.value = state.history[state.hpos]; ev.preventDefault();
      } else if (ev.key === 'ArrowDown' && state.history.length) {
        state.hpos = Math.min(state.history.length, state.hpos + 1); input.value = state.history[state.hpos] || ''; ev.preventDefault();
      }
    });
    btnHint.addEventListener('click', function () { stopDemo(); showHint(); });
    btnSol.addEventListener('click', function () { stopDemo(); showSolution(); });
    btnReset.addEventListener('click', function () { stopDemo(); resetAll(); input.focus(); });
    btnDemo.addEventListener('click', function () { if (state.demo) { stopDemo(); resetAll(); } else { startDemo(); } });
    banner.addEventListener('click', function () { stopDemo(); });

    /* ---- Démarrage ---- */
    redraw();
    print('Bienvenue ! Tapez des commandes Git et regardez le graphe évoluer. « help » liste les commandes.', 'gg-info');
    if (autoplay) { startDemo(); } else { input.focus({ preventScroll: true }); }

    return { repo: repo, submit: submit, reset: resetAll };
  }

  /* ================================================================
   * Export : navigateur (window.GitGraph) et Node.js (tests)
   * ================================================================ */
  var api = { Repo: Repo, Renderer: Renderer, layout: layout, exercise: exercise, tokenize: tokenize, version: '1.0.0' };
  if (typeof module !== 'undefined' && module.exports) { module.exports = api; }
  global.GitGraph = api;
})(typeof window !== 'undefined' ? window : globalThis);
