(function () {
    var gallery = document.querySelector('.gallery-grid');
    if (!gallery) return;

    var items = Array.prototype.slice.call(gallery.querySelectorAll('.gallery-item img'));
    if (!items.length) return;

    var current = 0;
    var overlay = document.createElement('div');
    overlay.className = 'lightbox';
    overlay.hidden = true;
    overlay.innerHTML =
        '<button class="lightbox-close" type="button" aria-label="Закрыть">&times;</button>' +
        '<button class="lightbox-arrow lightbox-arrow--prev" type="button" aria-label="Предыдущее фото">&#10094;</button>' +
        '<button class="lightbox-arrow lightbox-arrow--next" type="button" aria-label="Следующее фото">&#10095;</button>' +
        '<figure class="lightbox-figure">' +
        '<img class="lightbox-img" src="" alt="">' +
        '<figcaption class="lightbox-caption"></figcaption>' +
        '</figure>';

    document.body.appendChild(overlay);

    var imgEl = overlay.querySelector('.lightbox-img');
    var captionEl = overlay.querySelector('.lightbox-caption');
    var closeBtn = overlay.querySelector('.lightbox-close');
    var prevBtn = overlay.querySelector('.lightbox-arrow--prev');
    var nextBtn = overlay.querySelector('.lightbox-arrow--next');

    function show(index) {
        current = (index + items.length) % items.length;
        var source = items[current];
        imgEl.src = source.src;
        imgEl.alt = source.alt;
        captionEl.textContent = source.alt;
        overlay.hidden = false;
        document.body.classList.add('lightbox-open');
    }

    function hide() {
        overlay.hidden = true;
        document.body.classList.remove('lightbox-open');
        imgEl.removeAttribute('src');
    }

    gallery.querySelectorAll('.gallery-item').forEach(function (item, index) {
        item.setAttribute('role', 'button');
        item.setAttribute('tabindex', '0');
        item.setAttribute('aria-label', 'Открыть фото');

        item.addEventListener('click', function () {
            show(index);
        });

        item.addEventListener('keydown', function (event) {
            if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                show(index);
            }
        });
    });

    closeBtn.addEventListener('click', hide);
    prevBtn.addEventListener('click', function () { show(current - 1); });
    nextBtn.addEventListener('click', function () { show(current + 1); });

    overlay.addEventListener('click', function (event) {
        if (event.target === overlay) hide();
    });

    document.addEventListener('keydown', function (event) {
        if (overlay.hidden) return;

        if (event.key === 'Escape') hide();
        if (event.key === 'ArrowLeft') show(current - 1);
        if (event.key === 'ArrowRight') show(current + 1);
    });
})();
