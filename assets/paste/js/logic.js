/**
 * Paste UI interface written by javascript
 * Description: UI interface
 * Version: 0.1.0
 * Author:  Pavel Pronskiy
 * Contact: pavel.pronskiy@gmail.com
 * Copyright (c) 2016-2017 paste Pavel Pronskiy
***/

;(function($) {

	var icons = {
		'close': '<i class="fa fa-times" aria-hidden="true"></i>',
		'link': '<i class="fa fa-link" aria-hidden="true"></i>',
		'clock': '<i class="fa fa-clock-o" aria-hidden="true"></i>',
		'history': '<i class="fa fa-history" aria-hidden="true"></i>',
		'loading': '<i class="fa fa-spinner fa-spin fa-1x fa-fw"></i>'
	};

	var notice = {},
		opts = {},
		el = {}, css = {
		notice: {
			error: {
				'background-color':'rgba(241,111,92,1)'
			},
			success: {
				'background-color':'#2fd33f'
			}
		}
	};

/*	el.copyrightsContainer = $('<div/>', {
		'id': 'copyrights-wrapper',
		'html': '&mdash; Copyright by pp' +
				'<br />&mdash; Latest version: 0.1.0'
	});
*/
	el.contentContainer		= $('#content-container');
	el.submitIcon 			= $("#form-submit-icon");

	el.itemsContent 		= $('<div/>'		, { 'id': 'items-content-container' });
	el.noticeWrapper 		= $('<div/>'		, { 'id': 'notice-wrapper' });
	el.noticeContainer 		= $('<div/>'		, { 'id': 'notice-container' });
	el.headerContainer 		= $('<div/>'		, { 'id': 'header-content-container' });
	el.newMsgButton 		= $('<div/>'		, { 'id': 'new-message-button-container', 'text': '+ New' });
	el.histButton 			= $('<div/>'		, { 'id': 'history-button-container', 'text': '+ New' });
	el.histWrapper 			= $('<div/>'		, { 'id': 'history-wrapper' });
	el.histListContainer 	= $('<ul/>'			, { 'id': 'history-list-container' });
	el.formContainer 		= $('<div/>'		, { 'id': 'form-container' });
	el.form 				= $('<form/>'		, { 'id': 'paste-form', 'action': '' });
	el.textareaContainer 	= $('<div/>'		, { 'id': 'form-textarea-container' });
	el.textarea 			= $('<textarea/>'	, { 'id': 'textarea-form', 'name': 'paste', 'placeholder': settings.messages.placeholderTextarea });
	el.submitContainer 		= $('<div/>'		, { 'id': 'form-submit-container' });
	el.submitWrapper 		= $('<div/>'		, { 'id': 'form-submit-wrapper' });
	el.selectBoxWrapper		= $('<div/>'		, { 'id': 'selectbox-wrapper' });
	el.buttonExpireWrapper	= $('<div/>'		, { 'id': 'button-expire-wrapper' });
	el.postLoadingAnimation	= $('<div/>'		, { 'id': 'post-loading-animation' });
	el.selectBox			= $('<select/>'		, { 'id': 'selectbox' });
	el.submit 				= $('<button/>'		, { 'id': 'form-submit', 'type': 'submit', 'html': 'paste' });
	el.histContainer 		= $('<div/>'		, { 'id': 'history-container' });
	el.mSuccessContainer 	= $('<div/>' 		, { 'id': 'modal-success-container' });

	// el.copyrightsContainer.appendTo('body');
	el.itemsContent.appendTo(el.contentContainer);
	el.headerContainer.appendTo(el.itemsContent);
	el.formContainer.appendTo(el.itemsContent);
	el.form.appendTo(el.formContainer);
	el.textareaContainer.appendTo(el.form);
	el.textarea.appendTo(el.textareaContainer);
	el.submitWrapper.appendTo(el.form);
	el.submitContainer.appendTo(el.submitWrapper);
	el.submit.appendTo(el.submitContainer);
	el.noticeWrapper.appendTo(el.submitWrapper);
	el.noticeContainer.appendTo(el.noticeWrapper);
	el.headerContainer.prepend('<p><a href="' + window.location.origin + '">Text/Plain</a> Paste Service</p><h1>Pasting text/plain text and creating link for this text.</h1>');
	el.newMsgButton.appendTo(el.headerContainer);

	// el.postLoadingAnimation.appendTo(el.noticeContainer);
	// el.postLoadingAnimation.prepend('<i class="fa fa-spinner fa-spin fa-2x fa-fw"></i>');

	// el.histWrapper.appendTo(el.contentContainer);
	// el.histContainer.appendTo(el.histWrapper);
	// el.histContainer.prepend('<h1>' + icons.history + ' pastes history</h1>');
	// el.histListContainer.appendTo(el.histContainer);



	el.selectBoxWrapper.appendTo(el.submitWrapper);
	// el.submitContainer.addClass('fa fa-link');

	el.buttonExpireWrapper.appendTo(el.submitWrapper);
	el.buttonExpireWrapper.prepend('<div class="btn-switch">' +
		'<input type="radio" id="expire-yes" name="expire" class="btn-switch__radio btn-switch__radio_yes" value="true" />' +
		'<input type="radio" checked id="expire-no" name="expire" class="btn-switch__radio btn-switch__radio_no" value="false" />' +
		'<label for="expire-yes" class="btn-switch__label btn-switch__label_yes"><span class="btn-switch__txt">yes</span></label>' +
		'<label for="expire-no" class="btn-switch__label btn-switch__label_no"><span class="btn-switch__txt">no</span></label>' +
	'</div>' +
	'<div class="small-help">expire?</div>');

	// var css = {};
	var histPastes = {
		renderHistBlock: function(o, i) {
			var d = {};
			d.created = moment(o.created).fromNow();
			d.itemUrl = window.location.host + '/' + o.url;
			d.prepend = $('<li>', {
				'html': '<div>' +
					'<div>' +
						icons.link + ' <a href="//' + d.itemUrl + '/">' + d.itemUrl + '</a>' +
					'</div>' +
					'<div>' +
						'<span> ' + icons.clock + d.created + '</span>' +
					'</div>' +
				'</div>'
			});

			return el.histListContainer.prepend(d.prepend);
		},
		renderClientHistory: function(o) {
			el.histWrapper.appendTo(el.contentContainer);
			el.histContainer.appendTo(el.histWrapper);
			el.histContainer.prepend('<h1>' + icons.history + ' pastes history</h1>');
			el.histListContainer.appendTo(el.histContainer);

			o.data.forEach(this.renderHistBlock);
		},
		success: function(o) {
			switch(o.type) {
				case 'clientHistory': histPastes.renderClientHistory(o); break;
				default:
					if (settings.debug)
						console.log(o.type) ; break;
			}
		},
		error: function(o) {
			if (settings.debug)
				console.error(o);

		},
		empty: function(o) {
			if (settings.debug)
				console.log(o);

		},
		getHistPastes: function() {

			var ajax = {
				type: 'GET',
				url: '/api/pastes/' + settings.fingerprint,
				dataType: 'json',
				success: function(results){
					switch(results.status) {
						case 'success' :
							histPastes.success(results);
							break;
						case 'error' :
							histPastes.error(results);
							break;
						case 'empty' :
							histPastes.empty(results);
							break;
						default 	 :
							if (settings.debug)
								console.log(results);
							
							break;
					}
				},
				error: function(results) {
					if (settings.debug) {
						console.log(results);
						console.log('Empty history');
					}
				}
			};

			return $.ajax(ajax);
		}
	};

	notice.error = function(object) {
		
		if (settings.debug)
			console.log(object);

		el.noticeContainer.css(css.notice.error);
		el.noticeContainer.text(object.message);
		el.submit.prop('disabled', true);

		el.noticeContainer.fadeIn(settings.messagesFadeTimeInOut)
			.delay(settings.messagesViewTimeout)
			.queue(function (next) {
				$(this).fadeOut(settings.messagesFadeTimeInOut);
				el.submit.prop('disabled', false);
				next();
			});

		// console.error(message);
		return false;
	};

	notice.success = function(object) {

		var pasteLink = window.location.href + object.hashURL + '/';
		var successMessage = '<div id="message-url-container">' +
			'<div class="success-message-container">' +
				'<h3>Success!</h3>' +
				'<div class="message-link">' +
					'<a target="_blank" href="' + pasteLink + '">' + pasteLink + '</a>' +
				'</div>' +
				'<p>please click the link to paste clipboard</p>' +
				'<div class="close-message-url-container">' +
					icons.close +
				'</div>' +
			'</div>' +
		'</div>';

		el.submitIcon.html(icons.link);

		el.mSuccessContainer.html(successMessage);
		el.mSuccessContainer.appendTo(el.itemsContent);

		$('div.close-message-url-container').click(function() {
			el.mSuccessContainer.remove();
		});

		var clipboard = new Clipboard('#message-url-container', {
			text: function(trigger) {
				return pasteLink;
			}
		});

		histPastes.renderHistBlock({
			url: object.hashURL,
			created: object.created
		}, 0);

		if (settings.debug)
			console.log(object);

		return false;
	};

	el.form.submit(function(event) {

		opts.textarea = el.textarea.val();
		opts.key = settings.fingerprint;
		opts.type = '';
		opts.expire = $('input.btn-switch__radio:checked').val();
		opts.expire = typeof opts.expire == 'string' && opts.expire == 'true' ? true : false;

		// check textarea min max message length
		if (opts.textarea.length >= settings.maxMessageLength)
			return notice.error({
				'message' : settings.messages.maxLengthMessage
			});

		if (opts.textarea.length <= settings.minMessageLength)
			return notice.error({
				'message' : settings.messages.minLengthMessage
			});


		$.ajax({
			type: 'POST',
			url: '/api/post',
			dataType: 'json',
			data: opts,
			beforeSend: function() {
				el.submitIcon.html(icons.loading);
			},
			success: function(results){
				switch(results.status) {
					case 'success' : notice.success(results); break;
					case 'error' : notice.error(results); break;
					default 	 : console.log(results) ; break;
				}
			}
		});

		// event.preventDefault();
		return false;
	});

	new Fingerprint2({
		excludeUserAgent: true,
		excludeFlashFonts: true
	}).get(function(result){
		settings.fingerprint = result;
		histPastes.getHistPastes();
	});


})(jQuery);
