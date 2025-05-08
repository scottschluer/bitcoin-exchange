const CalculateBtcAmount = {
    mounted() {
        const form = this.el.closest('form');
        const usdInput = form.querySelector('input[name="amount"]');
        
        const btcPriceStr = this.el.dataset.btcPrice;
        const cleanPrice = btcPriceStr.replace(/[^0-9.-]/g, '');
        const btcPrice = parseFloat(cleanPrice);

        usdInput.addEventListener('input', (e) => {
            const usdAmount = parseFloat(e.target.value);
            if (!isNaN(usdAmount) && usdAmount > 0 && btcPrice > 0) {
                const btcAmount = usdAmount / btcPrice;
                this.el.textContent = btcAmount.toFixed(8) + ' BTC';
            } else {
                this.el.textContent = '0.00000000 BTC';
            }
        });
    }
};

const CalculateUsdAmount = {
    mounted() {
        const form = this.el.closest('form');
        const btcInput = form.querySelector('input[name="amount"]');
        
        const btcPriceStr = this.el.dataset.btcPrice;
        const cleanPrice = btcPriceStr.replace(/[^0-9.-]/g, '');
        const btcPrice = parseFloat(cleanPrice);

        btcInput.addEventListener('input', (e) => {
            const btcAmount = parseFloat(e.target.value);
            if (!isNaN(btcAmount) && btcAmount > 0 && btcPrice > 0) {
                const usdAmount = btcAmount * btcPrice;
                this.el.textContent = '$' + usdAmount.toFixed(2);
            } else {
                this.el.textContent = '$0.00';
            }
        });
    }
};

const InputValueSetter = {
    mounted() {
        this.handleEvent("set_input_value", ({ id, value }) => {
            const inputElement = document.getElementById(id);
            if (inputElement) {
                inputElement.value = value;
                inputElement.dispatchEvent(new Event('input', { bubbles: true }));
            }
        });
    }
};

export { CalculateBtcAmount, CalculateUsdAmount, InputValueSetter }; 