import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

KCMUtils.SimpleKCM {
    property string cfg_currency
    property alias cfg_backgroundStyle: styleBox.currentIndex
    property alias cfg_glassOpacity: opacitySlider.value

    // Same regions steamAF supports (lib/price.ts CURRENCY_CATALOG)
    readonly property var currencies: [
        "USD", "CAD", "BRL", "MXN", "ARS", "CLP", "COP", "PEN", "UYU", "CRC",
        "GBP", "EUR", "PLN", "CHF", "NOK", "SEK", "DKK", "CZK", "HUF", "RON",
        "TRY", "UAH", "ILS", "AED", "SAR", "QAR", "KWD", "ZAR", "KZT", "INR",
        "PKR", "IDR", "MYR", "PHP", "SGD", "THB", "VND", "TWD", "HKD", "CNY",
        "JPY", "KRW", "AUD", "NZD"
    ]

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: currencyBox
            Kirigami.FormData.label: i18n("Currency:")
            model: currencies
            currentIndex: Math.max(0, currencies.indexOf(cfg_currency))
            onActivated: cfg_currency = currencies[currentIndex]
        }

        QQC2.Label {
            text: i18n("Steam regional prices and verdicts for this store region.")
            color: Kirigami.Theme.disabledTextColor
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.ComboBox {
            id: styleBox
            Kirigami.FormData.label: i18n("Background:")
            model: [i18n("Solid"), i18n("Glass")]
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Glass opacity:")
            enabled: styleBox.currentIndex === 1
            spacing: Kirigami.Units.largeSpacing

            QQC2.Slider {
                id: opacitySlider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                from: 10
                to: 90
                stepSize: 5
                snapMode: QQC2.Slider.SnapAlways
            }

            QQC2.Label {
                text: opacitySlider.value + " %"
                font.bold: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            }
        }
    }
}
