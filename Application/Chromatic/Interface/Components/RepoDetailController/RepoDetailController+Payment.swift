//
//  RepoDetailController+Payment.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/25.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import DropDown
import SDWebImage
import SPIndicator
import UIKit

private struct DropDownActions {
    let text: String
    let block: (UIViewController, Repository) -> Void
}

private let paymentActions: [DropDownActions] = [
    .init(text: NSLocalizedString("SIGN_OUT", comment: "Sign Out"),
          block: { _, repo in
              PaymentManager.shared.deleteSignInRecord(for: repo.url)
              SPIndicator.present(title: NSLocalizedString("SUCCESS", comment: "Success"),
                                  message: nil,
                                  preset: .done,
                                  from: .top,
                                  completion: nil)
          }),
    .init(text: NSLocalizedString("PURCHASED", comment: "Purchased"),
          block: { controller, repo in
              DispatchQueue.main.async {
                  let alert = UIAlertController(title: "⏳",
                                                message: NSLocalizedString("COMMUNICATING_WITH_VENDER",
                                                                           comment: "Communicating with vender"),
                                                preferredStyle: .alert)
                  controller.present(alert, animated: true, completion: nil)
                  DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                      alert.dismiss(animated: true, completion: nil) // <- if any thing went wrong
                  }
                  DispatchQueue.global().async {
                      PaymentManager
                          .shared
                          .obtainUserAccountInfo(for: repo.url) { account in
                              DispatchQueue.main.async {
                                  guard let account = account else {
                                      alert.dismiss(animated: true, completion: nil)
                                      return
                                  }
                                  debugPrint(account)
                                  var builder = [Package]()
                                  for item in account.item {
                                      if let pkg = repo.metaPackage[item] {
                                          builder.append(pkg)
                                      }
                                  }
                                  let target = PackageCollectionController()
                                  target.dataSource = builder.sorted(by: { a, b in
                                      PackageCenter.default.name(of: a) < PackageCenter.default.name(of: b)
                                  })
                                  target.title = NSLocalizedString("PURCHASED", comment: "Purchased")
                                  alert.dismiss(animated: true) {
                                      controller.present(next: target)
                                  }
                              }
                          }
                  }
              }
          }),
]

class RepoPaymentView: UIView {
    let paymentIndicator = UIImageView()
    let button = UIButton()
    let xjh = UIActivityIndicatorView()
    let repo: Repository
    let endpoint: URL

    init(repo: Repository, endpoint: URL) {
        self.repo = repo
        self.endpoint = endpoint
        super.init(frame: CGRect())
        layer.cornerRadius = 8
        backgroundColor = .gray.withAlphaComponent(0.1)
        xjh.startAnimating()
        addSubview(xjh)
        xjh.snp.makeConstraints { x in
            x.center.equalToSuperview()
        }
        addSubview(button)
        button.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        button.addTarget(self, action: #selector(paymentBannerAction(sender:)), for: .touchUpInside)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(paymentChangeNotification),
                                               name: .RepositoryPaymenChanged,
                                               object: nil)
        addSubview(paymentIndicator)
        paymentIndicator.layer.cornerRadius = 8
        paymentIndicator.backgroundColor = .white
        paymentIndicator.snp.makeConstraints { x in
            x.trailing.equalToSuperview().offset(-8)
            x.centerY.equalToSuperview()
            x.width.equalTo(16)
            x.height.equalTo(16)
        }
        updateIndicator()

        DispatchQueue.global().async {
            let info = endpoint.appendingPathComponent("info")
            let request = URLRequest(url: info)
            URLSession
                .shared
                .dataTask(with: request) { [weak self] data, _, _ in
                    guard self != nil, let data = data else { return }
                    let jsonDicRead = try? JSONSerialization
                        .jsonObject(with: data, options: .allowFragments)
                    guard let jsonDic = jsonDicRead as? [String: Any] else {
                        return
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        let avatar = UIImageView()
                        let title = UILabel()

                        self.addSubview(avatar)
                        self.addSubview(title)

                        let avatarSize = 30
                        avatar.layer.cornerRadius = 8
                        avatar.clipsToBounds = true
                        avatar.contentMode = .scaleAspectFit
                        avatar.snp.makeConstraints { x in
                            x.centerY.equalToSuperview()
                            x.leading.equalToSuperview().offset(8)
                            x.height.equalTo(avatarSize)
                            x.width.equalTo(0)
                        }
                        if let icon = jsonDic["icon"] as? String,
                           let url = URL(string: icon)
                        {
                            SDWebImageManager.shared.loadImage(with: url,
                                                               options: .highPriority,
                                                               progress: nil)
                            { [weak self] image, _, _, _, _, _ in
                                guard self != nil, let image = image else { return }
                                avatar.image = image
                                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                                    avatar.snp.updateConstraints { x in
                                        x.width.equalTo(avatarSize)
                                    }
                                    self?.layoutIfNeeded()
                                }, completion: nil)
                            }
                        }

                        title.font = .boldSystemFont(ofSize: 10)
                        title.clipsToBounds = false
                        title.numberOfLines = 2
                        title.lineBreakMode = .byClipping
                        title.minimumScaleFactor = 0.5
                        title.textColor = UIColor(named: "RepoTableViewCell.Text")
                        title.snp.makeConstraints { x in
                            x.leading.equalTo(avatar.snp.trailing).offset(8)
                            x.trailing.equalTo(self.paymentIndicator.snp.leading).offset(-8)
                            x.top.equalTo(avatar.snp.top)
                            x.bottom.equalTo(avatar.snp.bottom)
                        }

                        if let authBanner = jsonDic["authentication_banner"] as? [String: String],
                           let promoteTitle = authBanner["message"]
                        {
                            title.text = promoteTitle
                        } else {
                            title.text = repo.nickName
                        }
                        self.xjh.stopAnimating()
                        self.xjh.isHidden = true
                    }
                }
                .resume()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    @objc
    func paymentBannerAction(sender: UIView) {
        sender.superview?.puddingAnimate()
        if !DeviceInfo.current.useRealDeviceInfo {
            let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                          message: NSLocalizedString("CANNOT_SIGNIN_PAYMENT_WITHOUT_REAL_DEVICE_ID", comment: "Cannot sign in without using real device identities, check your settings."),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"),
                                          style: .default,
                                          handler: nil))
            parentViewController?.present(alert, animated: true, completion: nil)
            return
        }
        let userInfo = PaymentManager.shared.obtainStoredTokenInfomation(for: repo)
        if userInfo == nil {
            PaymentManager.shared.startUserAuthenticate(window: window ?? UIWindow(),
                                                        controller: parentViewController,
                                                        repoUrl: repo.url) {
                DispatchQueue.main.async { [weak self] in
                    self?.updateIndicator()
                }
            }
        } else {
            let anchor = UIView()
            addSubview(anchor)
            anchor.snp.makeConstraints { x in
                x.leading.equalTo(self)
                x.bottom.equalTo(self).offset(5)
                x.width.equalTo(250)
                x.height.equalTo(0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let dropDown = DropDown(anchorView: anchor,
                                        selectionAction: { index, _ in
                                            paymentActions[index].block(self.parentViewController ?? UIViewController(), self.repo)
                                        },
                                        dataSource: paymentActions
                                            .map(\.text)
                                            .invisibleSpacePadding())
                dropDown.show(onTopOf: self.window)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    anchor.removeFromSuperview()
                }
            }
        }
    }

    @objc
    func paymentChangeNotification() {
        DispatchQueue.main.async { [self] in
            updateIndicator()
        }
    }

    func updateIndicator() {
        let userInfo = PaymentManager.shared.obtainStoredTokenInfomation(for: repo)
        if userInfo != nil {
            paymentIndicator.tintColor = .systemGreen
            paymentIndicator.image = .fluent(.checkmarkCircle24Filled)
        } else {
            paymentIndicator.tintColor = .systemOrange
            paymentIndicator.image = .fluent(.arrowRightCircle24Filled)
        }
    }
}

extension RepoDetailController {
    func setupPayment(withEndpoint: URL) -> UIView {
        let view = RepoPaymentView(repo: repo, endpoint: withEndpoint)
        return view
    }
}
