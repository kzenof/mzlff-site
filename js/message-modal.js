(function () {
    var openBtn = document.getElementById('openMessageBtn');
    var modal = document.getElementById('mailModal');
    if (!openBtn || !modal) return;

    var closeTriggers = modal.querySelectorAll('[data-mail-close]');

    function openModal() {
        modal.hidden = false;
        document.body.classList.add('mail-modal-open');
        modal.querySelector('.mail-modal__close').focus();
    }

    function closeModal() {
        modal.hidden = true;
        document.body.classList.remove('mail-modal-open');
        openBtn.focus();
    }

    openBtn.addEventListener('click', openModal);

    closeTriggers.forEach(function (el) {
        el.addEventListener('click', closeModal);
    });

    document.addEventListener('keydown', function (event) {
        if (modal.hidden) return;
        if (event.key === 'Escape') closeModal();
    });
})();
