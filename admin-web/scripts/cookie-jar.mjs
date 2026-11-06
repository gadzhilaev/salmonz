/** Minimal cookie jar for Node smoke tests (no deps). */
export class CookieJar {
  constructor() {
    this.map = new Map();
  }

  get(name) {
    return this.map.get(name);
  }

  has(name) {
    return this.map.has(name);
  }

  _store(res) {
    const raw = res.headers.getSetCookie?.() ?? [];
    for (const line of raw) {
      const [pair] = line.split(';');
      const i = pair.indexOf('=');
      if (i < 0) continue;
      const name = pair.slice(0, i).trim();
      const value = pair.slice(i + 1).trim();
      if (!value || line.toLowerCase().includes('max-age=0')) {
        this.map.delete(name);
      } else {
        this.map.set(name, value);
      }
    }
  }

  async fetch(url, init = {}) {
    const headers = new Headers(init.headers ?? {});
    if (this.map.size) {
      headers.set(
        'cookie',
        [...this.map.entries()].map(([k, v]) => `${k}=${v}`).join('; '),
      );
    }
    const res = await fetch(url, { ...init, headers });
    this._store(res);
    return res;
  }
}
