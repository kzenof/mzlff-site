(function () {
    const currentPage = document.body.dataset.page;
    if (currentPage) {
        document.querySelectorAll('.site-nav a[data-page]').forEach(function (link) {
            if (link.dataset.page === currentPage) {
                link.classList.add('active');
            }
        });
    }

    const navToggle = document.querySelector('.nav-toggle');
    const siteNav = document.querySelector('.site-nav');
    if (navToggle && siteNav) {
        navToggle.addEventListener('click', function () {
            siteNav.classList.toggle('open');
            navToggle.classList.toggle('open');
        });
    }

    const scrollBtn = document.getElementById('scrollToTop');
    if (scrollBtn) {
        window.addEventListener('scroll', function () {
            scrollBtn.style.display = window.pageYOffset > 300 ? 'block' : 'none';
        });

        scrollBtn.addEventListener('click', function () {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        });
    }
})();
