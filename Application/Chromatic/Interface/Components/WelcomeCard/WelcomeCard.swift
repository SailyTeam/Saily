//
//  WelcomeCard.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import FluentIcon
import SDWebImage
import SnapKit
import UIKit

class WelcomeCard: UIView {
    private var backgroundView = AppleCardColorView()
    private var headIconContainer = UIView()
    private var headIconView = UIImageView()
    private var welcomeTitleLabel = UILabel()
    private var welcomeTintLabel = UILabel()

    private var touchHandlerIcon = UIButton()
    private var touchHandlerCard = UIButton()

    private var cardClosure: () -> Void
    private var headIconClosure: () -> Void

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    required init(onTouchAvatar: @escaping () -> Void,
                  onTouchCard: @escaping () -> Void)
    {
        cardClosure = onTouchCard
        headIconClosure = onTouchAvatar

        super.init(frame: CGRect())

        // self
        backgroundColor = UIColor(named: "WelcomeCard.Background")
        clipsToBounds = true
        layer.cornerRadius = 14

        backgroundView.layer.cornerRadius = 14
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        // card touch
        touchHandlerCard.addTarget(self, action: #selector(whenTouched), for: .touchUpInside)
        addSubview(touchHandlerCard)
        touchHandlerCard.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        // headicon
        headIconContainer.layer.cornerRadius = 34
        addSubview(headIconContainer)
        headIconContainer.snp.makeConstraints { x in
            x.centerX.equalTo(self.snp.centerX)
            x.bottom.equalTo(self.snp.centerY).offset(20)
            x.height.equalTo(68)
            x.width.equalTo(68)
        }

        headIconView.tintColor = UIColor(named: "BUTTON_NORMAL")
        headIconView.contentMode = .scaleAspectFill
        headIconView.layer.cornerRadius = 34.5
        headIconView.clipsToBounds = true
        headIconContainer.addSubview(headIconView)
        headIconView.snp.makeConstraints { x in
            x.edges.equalTo(headIconContainer)
        }

        // labels
        welcomeTintLabel.text = NSLocalizedString("WELCOME_CARD_DESC", comment: "While the world sleeps, we dream!")
        welcomeTintLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        welcomeTintLabel.textAlignment = .left
        welcomeTintLabel.textColor = UIColor(named: "WelcomeCard.Title")
        welcomeTitleLabel.text = NSLocalizedString("WELCOME_CARD_TITLE", comment: "Welcome to Saily!")
        welcomeTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        welcomeTitleLabel.textAlignment = .left
        welcomeTitleLabel.textColor = UIColor(named: "WelcomeCard.Title")
        addSubview(welcomeTintLabel)
        addSubview(welcomeTitleLabel)
        welcomeTintLabel.snp.makeConstraints { x in
            x.leading.equalToSuperview().offset(18)
            x.trailing.equalToSuperview().offset(-18)
            x.height.equalTo(22)
            x.bottom.equalTo(self.snp.bottom).offset(-12)
        }
        welcomeTitleLabel.snp.makeConstraints { x in
            x.leading.equalToSuperview().offset(18)
            x.trailing.equalToSuperview().offset(-18)
            x.height.equalTo(28)
            x.bottom.equalTo(welcomeTintLabel.snp.top).offset(6)
        }

        // icon touch
        touchHandlerIcon.addTarget(self, action: #selector(whenTouchedIcon), for: .touchUpInside)
        addSubview(touchHandlerIcon)
        touchHandlerIcon.snp.makeConstraints { x in
            x.edges.equalTo(headIconContainer.snp.edges)
        }

        updateAvatar()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateAvatar),
                                               name: .AppleCardAvatarUpdated,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func updateAvatar() {
        DispatchQueue.main.async { [self] in
            var avatarLoaded: Bool = false
            defer {
                if avatarLoaded {
                    headIconView.contentMode = .scaleAspectFill
                } else {
                    let config = UIImage.SymbolConfiguration(
                        pointSize: 24,
                        weight: .bold
                    )
                    headIconView.image = UIImage(
                        systemName: "rosette",
                        withConfiguration: config
                    )
                    headIconView.contentMode = .center
                }
            }
            if let data = UserDefaults
                .standard
                .value(forKey: "wiki.qaq.chromatic.userAvatar") as? Data,
                let image = UIImage(data: data)
            {
                headIconView.image = image
                avatarLoaded = true
            } else {
                let scale = Int(UIScreen.main.scale)
                let filename = scale == 1 ? "AppleAccountIcon" : "AppleAccountIcon@\(scale)x"
                let path = documentsDirectory
                    .appendingPathComponent(filename)
                    .appendingPathExtension("png")
                    .path
                if let image = UIImage(contentsOfFile: path) {
                    headIconView.image = image
                    avatarLoaded = true
                }
            }
        }
    }

    @objc
    func whenTouched() {
        DispatchQueue.main.async {
            self.cardClosure()
        }
        puddingAnimate()
    }

    @objc
    func whenTouchedIcon() {
        DispatchQueue.main.async {
            self.headIconClosure()
        }
        headIconContainer.puddingAnimate()
    }
}
