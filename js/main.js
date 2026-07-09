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

    const headerInner = document.querySelector('.header-inner');
    if (headerInner && !headerInner.querySelector('.theme-toggle')) {
        const themeBtn = document.createElement('button');
        themeBtn.className = 'theme-toggle';
        themeBtn.type = 'button';
        themeBtn.setAttribute('aria-label', 'Переключить тему');
        themeBtn.innerHTML = '<span class="theme-toggle-icon" aria-hidden="true"></span>';

        if (navToggle) {
            headerInner.insertBefore(themeBtn, navToggle);
        } else {
            headerInner.appendChild(themeBtn);
        }

        themeBtn.addEventListener('click', function () {
            const isLight = document.documentElement.getAttribute('data-theme') === 'light';
            if (isLight) {
                document.documentElement.removeAttribute('data-theme');
                localStorage.setItem('mzlff-theme', 'dark');
            } else {
                document.documentElement.setAttribute('data-theme', 'light');
                localStorage.setItem('mzlff-theme', 'light');
            }
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
