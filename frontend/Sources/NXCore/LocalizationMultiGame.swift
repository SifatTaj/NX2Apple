import Foundation

extension L10n {
    package static func multiGameString(_ key: String, _ lang: Lang) -> String? {
        guard let row = multiGameTable[key] else { return nil }
        return row[lang] ?? row[.en] ?? key
    }

    private static let multiGameTable: [String: [Lang: String]] = [
        "msg.multiGameDetected": [
            .en: "Multi-game cartridge dump (%d games): building game %d of %d (%@)",
            .zh: "多游戏卡带镜像（共 %d 个游戏）：正在构建第 %d 个，共 %d 个（%@）",
            .de: "Multi-Spiel-Cartridge-Dump (%d Spiele): baue Spiel %d von %d (%@)",
            .sv: "Spelsamlingsavbildning (%d spel): bygger spel %d av %d (%@)",
            .fr: "Image de cartouche multi-jeux (%d jeux) : compilation du jeu %d sur %d (%@)",
        ],
        "msg.multiGameDone": [
            .en: "Done! Built %d games from multi-game cartridge dump.",
            .zh: "完成！已从多游戏卡带镜像中构建 %d 个游戏。",
            .de: "Fertig! %d Spiele aus Multi-Spiel-Cartridge-Dump gebaut.",
            .sv: "Klar! Byggde %d spel från spelsamlingsavbildningen.",
            .fr: "Terminé ! %d jeux compilés depuis l’image de cartouche multi-jeux.",
        ],
    ]
}

