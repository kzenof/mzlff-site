(function () {
    const TYPE_LABELS = { album: 'Альбом', single: 'Сингл', ep: 'EP' };

    function createCover(release) {
        if (release.cover) {
            const img = document.createElement('img');
            img.src = release.cover;
            img.alt = release.title;
            img.loading = 'lazy';
            return img;
        }
        const placeholder = document.createElement('div');
        placeholder.className = 'release-cover-placeholder';
        placeholder.textContent = release.title.charAt(0).toUpperCase();
        return placeholder;
    }

    function createCard(release) {
        const card = document.createElement('article');
        card.className = 'release-card';

        const coverWrap = document.createElement('div');
        coverWrap.className = 'release-cover';
        coverWrap.appendChild(createCover(release));
        card.appendChild(coverWrap);

        const info = document.createElement('div');
        info.className = 'release-info';

        const title = document.createElement('h3');
        title.textContent = release.title;
        info.appendChild(title);

        if (release.featuring) {
            const feat = document.createElement('p');
            feat.className = 'release-feat';
            feat.textContent = 'ft. ' + release.featuring;
            info.appendChild(feat);
        }

        const meta = document.createElement('p');
        meta.className = 'release-meta';
        meta.textContent = release.year + ' · ' + (TYPE_LABELS[release.type] || release.type);
        info.appendChild(meta);

        const link = document.createElement('a');
        link.href = release.link;
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        link.className = 'release-link';
        link.textContent = 'Слушать';
        info.appendChild(link);

        card.appendChild(info);
        return card;
    }

    function renderReleases(container, releases) {
        container.innerHTML = '';
        releases.forEach(function (release) {
            container.appendChild(createCard(release));
        });
    }

    function applyData(data) {
        const containers = document.querySelectorAll('[data-releases]');
        if (!containers.length || !data || !data.releases) return;

        const sorted = data.releases.slice().sort(function (a, b) {
            return b.year - a.year;
        });

        containers.forEach(function (container) {
            const mode = container.dataset.releases;
            let list = sorted;

            if (mode === 'recent') {
                list = sorted.slice(0, 6);
            } else if (mode === 'all') {
                list = sorted;
            } else if (mode === 'albums') {
                list = sorted.filter(function (r) {
                    return r.type === 'album' || r.type === 'ep';
                });
            } else if (mode === 'singles') {
                list = sorted.filter(function (r) {
                    return r.type === 'single';
                });
            }

            renderReleases(container, list);
        });
    }

    function showError() {
        const slug = document.body.dataset.artist || 'mzlff';
        document.querySelectorAll('[data-releases]').forEach(function (container) {
            container.innerHTML = '<p class="releases-error">Не удалось загрузить релизы. Запусти update-and-push-' + slug + '.ps1</p>';
        });
    }

    if (window.RELEASES_DATA) {
        applyData(window.RELEASES_DATA);
        return;
    }

    const slug = document.body.dataset.artist || 'mzlff';
    fetch(new URL('data/releases.json', window.location.href))
        .then(function (response) {
            if (!response.ok) throw new Error('fetch failed');
            return response.json();
        })
        .then(applyData)
        .catch(showError);
})();
