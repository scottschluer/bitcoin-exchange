import Chart from 'chart.js/auto';

const PriceChartHook = {
    mounted() {
        this.initializeChart();
        this.setupThemeChangeListener();
        this.updateChartWithMockData();
    },

    handleEvent(event, data) {
        if (event === "price_history_updated" && data) {
            this.updateChart(data);
        }
    },
    
    initializeChart() {
        const ctx = this.el.getContext('2d');
        const gradient = this.createGradient(ctx);
        
        const config = {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    data: [],
                    borderColor: this.isDarkMode() ? '#f6b87e' : '#f59e0b',
                    borderWidth: 1.5,
                    tension: 0.1,
                    pointRadius: 0,
                    fill: true,
                    backgroundColor: gradient,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        enabled: false
                    }
                },
                scales: {
                    x: {
                        display: false
                    },
                    y: {
                        display: false
                    }
                },
                animation: {
                    duration: 1000
                }
            }
        };
        
        this.chart = new Chart(ctx, config);
    },
    
    createGradient(ctx) {
        const gradient = ctx.createLinearGradient(0, 0, 0, 400);
        
        if (this.isDarkMode()) {
            gradient.addColorStop(0, 'rgba(246, 184, 126, 0.5)');
            gradient.addColorStop(1, 'rgba(246, 184, 126, 0)');
        } else {
            gradient.addColorStop(0, 'rgba(245, 158, 11, 0.5)');
            gradient.addColorStop(1, 'rgba(245, 158, 11, 0)');
        }
        
        return gradient;
    },
    
    updateChartWithMockData() {
        const dataPoints = 288;
        const labels = Array.from({ length: dataPoints }, (_, i) => {
            const date = new Date();
            date.setMinutes(date.getMinutes() - (dataPoints - i) * 5);
            return date.toISOString();
        });
        
        const basePrice = 95000;
        const trendData = this.generateTrendData(dataPoints, basePrice);
        
        this.updateChart({
            labels: labels,
            data: trendData
        });
    },
    
    generateTrendData(count, basePrice) {
        let data = [];
        let currentPrice = basePrice;
        
        const volatility = 0.005;
        const drift = 0.0005;
        const jumpProbability = 0.03;
        const jumpMagnitude = 0.02;
        
        const trendProfile = [0.3, 0.5, 0.7, 0.9, 1.0, 0.95];
        
        data.push(currentPrice);
        
        for (let i = 1; i < count; i++) {
            const trendIndex = Math.floor(i / count * trendProfile.length);
            const trendFactor = trendProfile[Math.min(trendIndex, trendProfile.length - 1)];
            
            const randomReturn = (Math.random() * 2 - 1) * volatility;
            const trendReturn = drift * trendFactor;
            
            const hasJump = Math.random() < jumpProbability;
            const jumpReturn = hasJump ? (Math.random() - 0.5) * jumpMagnitude : 0;
            
            const percentChange = randomReturn + trendReturn + jumpReturn;
            currentPrice = currentPrice * (1 + percentChange);
            
            const maxDeviation = basePrice * 0.15;
            const trendTarget = basePrice * (0.9 + trendFactor * 0.2);
            
            if (Math.abs(currentPrice - trendTarget) > maxDeviation) {
                currentPrice = currentPrice + (trendTarget - currentPrice) * 0.1;
            }
            
            data.push(currentPrice);
        }
        
        return data;
    },
    
    updateChart(chartData) {
        if (!this.chart) return;
        
        this.chart.data.labels = chartData.labels || [];
        this.chart.data.datasets[0].data = chartData.data || [];
        
        this.chart.update();
    },
    
    isDarkMode() {
        return document.documentElement.classList.contains('dark');
    },
    
    setupThemeChangeListener() {
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.attributeName === 'class') {
                    this.updateChartTheme();
                }
            });
        });
        
        observer.observe(document.documentElement, {
            attributes: true,
            attributeFilter: ['class']
        });
    },
    
    updateChartTheme() {
        if (!this.chart) return;
        
        const ctx = this.el.getContext('2d');
        const gradient = this.createGradient(ctx);
        
        this.chart.data.datasets[0].backgroundColor = gradient;
        this.chart.data.datasets[0].borderColor = this.isDarkMode() ? '#f6b87e' : '#f59e0b';
        
        this.chart.update();
    }
};

export default PriceChartHook;