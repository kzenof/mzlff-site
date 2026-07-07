(function () {
    const carousel = document.querySelector('.hero-carousel');
    if (!carousel) return;

    const slides = carousel.querySelectorAll('.carousel-slide');
    const dotsContainer = carousel.querySelector('.carousel-dots');
    const prevBtn = carousel.querySelector('.carousel-arrow--prev');
    const nextBtn = carousel.querySelector('.carousel-arrow--next');
    let current = 0;
    let timer;

    slides.forEach(function (_, index) {
        const dot = document.createElement('button');
        dot.className = 'carousel-dot' + (index === 0 ? ' active' : '');
        dot.setAttribute('aria-label', 'Слайд ' + (index + 1));
        dot.addEventListener('click', function () {
            goTo(index);
            resetTimer();
        });
        dotsContainer.appendChild(dot);
    });

    const dots = dotsContainer.querySelectorAll('.carousel-dot');

    function goTo(index) {
        slides[current].classList.remove('active');
        dots[current].classList.remove('active');
        current = (index + slides.length) % slides.length;
        slides[current].classList.add('active');
        dots[current].classList.add('active');
    }

    function next() {
        goTo(current + 1);
    }

    function prev() {
        goTo(current - 1);
    }

    function resetTimer() {
        clearInterval(timer);
        timer = setInterval(next, 5000);
    }

    if (prevBtn) {
        prevBtn.addEventListener('click', function () {
            prev();
            resetTimer();
        });
    }

    if (nextBtn) {
        nextBtn.addEventListener('click', function () {
            next();
            resetTimer();
        });
    }

    resetTimer();
})();
