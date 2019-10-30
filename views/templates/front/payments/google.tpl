<form name="{$module}" id="{$module}-google-form" action="{$link->getModuleLink($module, 'placeorder', [], true)|escape:'html'}" data-key="{$CHECKOUTCOM_PUBLIC_KEY}" data-merchantid="{$merchantid}" data-live="{$live}" data-invoiceid="{$invoiceid}" method="POST">
	<input id="{$module}-google-source" type="hidden" name="source" value="google" required>
	<input type="hidden" id="{$module}-google-token" name="token" value="" />
</form>
{literal}
<script type="text/javascript">
	/**
	 * Checkout Google Pay Class.
	 *
	 * @class      CheckoutcomGooglePay (name)
	 * @param      {<type>}    $form   The form
	 * @return     {Function}  { description_of_the_return_value }
	 */
	function CheckoutcomGooglePay($form) {

		/**
		 * Safe check
		 */
		if(typeof window.checkoutcom === 'undefined') {
			window.checkoutcom = new Object();
			//window.checkoutcom.$confirmation = document.getElementById('payment-confirmation');
		}

		/**
		 * Constants
		 */
		const baseRequest = {
			apiVersion: 2,
		  	apiVersionMinor: 0
		},
			tokenizationSpecification = {
			  type: 'PAYMENT_GATEWAY',
			  parameters: {
			    'gateway': 'checkoutltd',
			    'gatewayMerchantId': $form.dataset.key
			  }
		},
			allowedPaymentMethods = ['CARD', 'TOKENIZED_CARD'],
			allowedCardNetworks = getAllowedCardNetworks(),
			allowedCardAuthMethods = ["PAN_ONLY", "CRYPTOGRAM_3DS"],
			baseCardPaymentMethod = {
				type: 'CARD',
				parameters: {
					allowedAuthMethods: allowedCardAuthMethods,
					allowedCardNetworks: allowedCardNetworks
				}
		},
			cardPaymentMethod = Object.assign({tokenizationSpecification: tokenizationSpecification}, baseCardPaymentMethod),
			paymentsClient = new window.google.payments.api.PaymentsClient({environment: +$form.dataset.live ? 'PRODUCTION' : 'TEST'}),
			isReadyToPayRequest = Object.assign({}, baseRequest),
			$input = document.getElementById('checkoutcom-google-token');

		isReadyToPayRequest.allowedPaymentMethods = [baseCardPaymentMethod];

		/**
		 * Make it global
		 */
		window.checkoutcom.google = this;

		/**
		 * Init payments client.
		 */
		paymentsClient.isReadyToPay(isReadyToPayRequest).then(function(response) {

			if (response.result) {
				// Add Google Pay button to the page
				insertButton();
				prefetchData();
			} else {
				this.hide(response);
			}

		}).catch(function(err) {
			window.checkoutcom.google.hide(err);
	    });


	    /**
	     * Protected methods
	     */

	    /**
	     * Gets the allowed card networks.
	     *
	     * @return     {Array}  The allowed card networks.
	     */
	    function getAllowedCardNetworks() {

	     	var brazilian = [];
	     	if(prestashop.customer.addresses[$form.dataset.invoiceid].country_iso === "BR") {
	     		brazilian = ["ELECTRON", "MAESTRO"];
	     	}

	     	return ["AMEX", "DISCOVER", "JCB", "MASTERCARD", "VISA"].concat(brazilian);

	    }

	    /**
	     * Create Google Pay Button.
	     */
		function insertButton() {
	     	// Google Pay Form Enter
			$form.addEventListener("form:show", function(event) {
				// Hide core confirmation
				window.checkoutcom.$confirmation.childNodes[1].style.display = 'none';

				// Create Google Pay button
				const button = paymentsClient.createButton({onClick: handleClick});
				button.id = 'checkoutcom-google-pay';
				window.checkoutcom.$confirmation.appendChild(button);
			});

			// Google Pay Form Exit
			$form.addEventListener("form:hide", function(event) {
				// Show confirmation button
				window.checkoutcom.$confirmation.childNodes[1].style.display = 'inline-block';
				document.getElementById('checkoutcom-google-pay').remove();
			});
		}

		/**
		 * Generate reques
		 *
		 * @return     {<type>}  The request.
		 */
		function getRequest() {

			const paymentDataRequest = Object.assign({}, baseRequest);
			paymentDataRequest.allowedPaymentMethods = [cardPaymentMethod];

			paymentDataRequest.transactionInfo = {
			  totalPriceStatus: 'FINAL',
			  totalPrice: '' + prestashop.cart.totals.total.amount, // Cast to string. Must be string.
			  currencyCode: prestashop.currency.iso_code,
			  countryCode: prestashop.customer.addresses[$form.dataset.invoiceid].country_iso //@todo: verify this; merchant or billing country?
			};

			paymentDataRequest.merchantInfo = {
			  merchantName: prestashop.shop.name,
			  merchantId: $form.dataset.merchantid
			};

			return paymentDataRequest;
		}

		/**
		 * Prefetch Data for performance.
		 */
		function prefetchData() {
			paymentsClient.prefetchPaymentData(getRequest());
		}

		/**
		 * Hanle Google Pay click.
		 */
		function handleClick() {

			paymentsClient.loadPaymentData(getRequest()).then(function(paymentData){
				$input.value = paymentData.paymentMethodData.tokenizationData.token;
				$form.submit();
			}).catch(function(err){
				window.checkoutcom.google.hide(err);
			});

		}

		/**
		 * Write to console.
		 *
		 * @param      {mixed}  reason  The reason
		 */
		function write(reason) {
			console.log('checkoutcom-google-form', reason);
		}


	    /**
	     * Public methods
	     */

	    /**
	     * Hide Google Pay option from the DOM.
	     *
	     * @param      {<type>}  reason  The reason
	     */
		this.hide = function(reason) {
	    	console.log("hide google pay option", reason);
	    	write(reason);
	    };


	    /**
	     * Form submit event.
	     */
		$form.onsubmit = function(e) {
			if(!$input.value) {
				write('Missing token.');
				e.preventDefault();
			}
    	};

	}
</script>
<script type="text/javascript" async src="https://pay.google.com/gp/p/js/pay.js" onload="CheckoutcomGooglePay(document.getElementById('checkoutcom-google-form'))"></script>
{/literal}
