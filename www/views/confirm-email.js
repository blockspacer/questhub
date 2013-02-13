pp.views.ConfirmEmail = pp.View.Common.extend({
    t: 'confirm-email',
    selfRender: true,
    afterInitialize: function () {
        $.post('http://localhost:3000/api/register/confirm_email', this.options)
        .done(function () {
            pp.app.view.notify('success', 'Email confirmed.');
            pp.app.router.navigate('/', { trigger: true });
        })
        .fail(function (response) {
            pp.app.onError(false, response);
            pp.app.router.navigate('/', { trigger: true });
        });
    }
});