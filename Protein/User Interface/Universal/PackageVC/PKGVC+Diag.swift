//
//  PKGVC+Diag.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/12.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class PackageDiagViewController: UIViewControllerWithCustomizedNavBar {

    private let tableView = UITableView()
    private var welcomeHeight: CGFloat = 75
    
    override func viewDidLoad() {
        defer {
            setupNavigationBar()
            makeSimpleNavBarGreatAgain(withName: "Done".localized())
            tableView.snp.makeConstraints { (x) in
                x.top.equalTo(self.SimpleNavBar.snp.bottom)
                x.right.equalToSuperview()
                x.left.equalToSuperview()
                x.bottom.equalToSuperview()
            }
        }
        
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(PackageDiagCell.self, forCellReuseIdentifier: "wiki.qaq.Protein.PackageDiagCell")
        view.addSubview(tableView)
        
    }
    
    private var package: PackageStruct? = nil
    private var diagInfo: PackageResolveReturn? = nil
    func loadData(withPackage: PackageStruct, andResolveObject: PackageResolveReturn) {
        package = withPackage
        diagInfo = andResolveObject
        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        tableView.reloadData()
    }
    
}

extension PackageDiagViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        if section == 2 {
            return 1
        }
        if let diag = diagInfo {
            if diag.failed.count == 0 {
                return diag.extraDelete.count + 1
            }
            return diag.failed.count + diag.extraInstall.count + diag.extraDelete.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return welcomeHeight
        }
        return 75
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "wiki.qaq.Protein.PackageDiagCell", for: indexPath) as! PackageDiagCell
        
        if indexPath.section == 0, let package = package {
            cell.setForPackageDescription(withPackage: package) { (height) in
                if height != self.welcomeHeight {
                    self.welcomeHeight = height + 8
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
            }
            return cell
        }
        
        if indexPath.section == 2 {
            cell.setForDescription(withText: "PackageDiagnosis_GoToIssue".localized()) { (_) in }
            return cell
        }
        
        if let diag = diagInfo {
            if diag.failed.count == 0 {
                // package required by other packages
                if indexPath.row >= diag.extraDelete.count {
                    cell.setCondition(title: "PackageDiagnosis_PackageRequiredTryFix".localized() ,
                                      descriptionText: "PackageDiagnosis_PackageRequiredTryFixHint".localized(), mets: false)
                    cell.setIcon(withImage: UIImage(named: "PKGVC.solution"))
                } else {
                    let item = diag.extraDelete[indexPath.row]
                    cell.setCondition(title: "PackageDiagnosis_PackageRequired".localized() + ": " + item ,
                                      descriptionText: "PackageDiagnosis_PackageRequiredHint".localized(), mets: false)
                }
            } else {
                let diagFailedCount = diag.failed.count
                let diagExtraInstall = diag.extraInstall.count
                
                if indexPath.row < diagFailedCount {
                    let item = diag.failed[indexPath.row]
                    var title = "Group".localized() + " " + String(indexPath.row + 1) + " : "
                    var foo = false
                    for item in item.conditions.first ?? [] {
                        foo = true
                        title += item.identity
                        switch item.mets {
                        case .any: break
                        case .bigger: title += " (>" + (item.metsRecord ?? "") + ")"
                        case .biggerOrEqual: title += " (>=" + (item.metsRecord ?? "") + ")"
                        case .equal: title += " (=" + (item.metsRecord ?? "") + ")"
                        case .smaller: title += " (<" + (item.metsRecord ?? "") + ")"
                        case .smallerOrEqual: title += " (>=" + (item.metsRecord ?? "") + ")"
                        }
                        title += ", "
                    }
                    if foo {
                        title.removeLast(2)
                    }
                    var desc = ""
                    if item.majorType == .depends {
                        desc = "PackageDiagnosis_DependsHint".localized()
                    } else if item.majorType == .conflict {
                        desc = "PackageDiagnosis_ConflictHint".localized()
                    }
                    cell.setCondition(title: title, descriptionText: desc, mets: false)
                } else if indexPath.row < diagFailedCount + diagExtraInstall {
                    let item = diag.extraInstall[indexPath.row - diagFailedCount]
                    cell.setCondition(title: "PackageDiagnosis_ExtraInstall".localized() + ": " + item.obtainNameIfExists(),
                                      descriptionText: "PackageDiagnosis_ExtraInstallHint".localized(), mets: true)
                } else {
                    let item = diag.extraDelete[indexPath.row - diagFailedCount - diagExtraInstall]
                    cell.setCondition(title: "PackageDiagnosis_ExtraDelete".localized() + ": " + item,
                                      descriptionText: "PackageDiagnosis_ExtraDeleteHint".localized(), mets: true)
                }
            }
            
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let container = UIView()
            container.backgroundColor = self.view.backgroundColor
            let label = UILabel()
            label.font = .systemFont(ofSize: 24, weight: .bold)
            label.text = "PackageDiagnosis".localized()
            container.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.left.equalToSuperview().offset(28)
                x.height.equalTo(60)
                x.bottom.equalToSuperview().offset(-10)
                x.right.equalToSuperview()
            }
            return container
        case 1:
            let container = UIView()
            container.backgroundColor = self.view.backgroundColor
            let label = UILabel()
            label.font = .systemFont(ofSize: 18, weight: .semibold)
            label.text = "PackageDiagnosis_ConditionGroup".localized()
            container.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.left.equalToSuperview().offset(28)
                x.height.equalToSuperview()
                x.bottom.equalToSuperview()
                x.right.equalToSuperview()
            }
            return container
        case 2:
            let container = UIView()
            container.backgroundColor = self.view.backgroundColor
            let label = UILabel()
            label.font = .systemFont(ofSize: 18, weight: .semibold)
            label.text = "PackageDiagnosis_Help".localized()
            container.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.left.equalToSuperview().offset(28)
                x.height.equalToSuperview()
                x.bottom.equalToSuperview()
                x.right.equalToSuperview()
            }
            return container
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 80
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.puddingAnimate()
        
        if indexPath.section == 1 {
            if let diag = diagInfo {
                if diag.failed.count == 0 {
                    if indexPath.row >= diag.extraDelete.count {
                        tryFixBrokenDeleteQueue()
                    } else {
                        // look up inside installed
                        let capture = PackageManager.shared.rawInstalled
                        for item in capture where item.identity == diag.extraDelete[indexPath.row] {
                            let pop = PackageViewController()
                            pop.modalPresentationStyle = .formSheet;
                            pop.modalTransitionStyle = .coverVertical;
                            pop.PackageObject = item
                            pop.preferredContentSize = self.preferredContentSize
                            self.present(pop, animated: true) { }
                            return
                        }
                    }
                } else {
                    // detect what do user do
                    let row = indexPath.row
                    if row < diag.failed.count {
                        // do nothing
                        return
                    } else if row < diag.failed.count + diag.extraInstall.count {
                        // install
                        let pkg = diag.extraInstall[row - diag.failed.count]
                        let pop = PackageViewController()
                        pop.modalPresentationStyle = .formSheet;
                        pop.modalTransitionStyle = .coverVertical;
                        pop.PackageObject = pkg
                        pop.preferredContentSize = self.preferredContentSize
                        self.present(pop, animated: true) { }
                        return
                    } else {
                        // delete
                        let capture = PackageManager.shared.rawInstalled
                        for item in capture where item.identity == diag.extraDelete[row - diag.failed.count - diag.extraInstall.count] {
                            let pop = PackageViewController()
                            pop.modalPresentationStyle = .formSheet;
                            pop.modalTransitionStyle = .coverVertical;
                            pop.PackageObject = item
                            pop.preferredContentSize = self.preferredContentSize
                            self.present(pop, animated: true) { }
                            return
                        }
                    }
                    
                }
                // look for packages
                
                return
            }
        }
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                self.dismiss(animated: true, completion: nil)
                guard let url = URL(string: DEFINE.SOURCE_CODE_LOCATION +  "/issues") else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
    }
    
    func tryFixBrokenDeleteQueue() {
        if let diag = diagInfo, let pkg = package {
            var list = [String]()
            for item in diag.extraDelete {
                list.append(item)
            }
            list.append(pkg.identity)
            let attempt = TaskManager.shared.callForDeleteAllSolutionAndReturnDidSuccess(withList: list)
            if !attempt {
                let alert = UIAlertController(title: "Error".localized(), message: "PackageDiagnosis_PackageRequiredTryFixFailedHint".localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}

fileprivate class PackageDiagCell: UITableViewCell {
    
    private let container = UIView()
    private let icon = UIImageView()
    private let name = UILabel()
    private let desc = UILabel()
    let textView = UITextView()
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectedBackgroundView = UIView()
        
        addSubview(container)
        container.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        
        container.addSubview(icon)
        container.addSubview(name)
        container.addSubview(desc)
        container.addSubview(textView)
        
        icon.contentMode = .scaleAspectFill
        icon.layer.cornerRadius = 20
        icon.snp.makeConstraints { (x) in
            x.centerY.equalToSuperview()
            x.left.equalTo(self.container.snp.left).offset(12)
            x.width.equalTo(20)
            x.height.equalTo(20)
        }
        
        name.textColor = UIColor(named: "RepoTableViewCell.Text")
        name.font = .monospacedSystemFont(ofSize: 18, weight: .semibold)
        name.snp.makeConstraints { (x) in
            x.left.equalTo(icon.snp.right).offset(12)
            x.bottom.equalTo(icon.snp.centerY).offset(4)
        }
        desc.numberOfLines = 0
        desc.lineBreakMode = .byWordWrapping
        desc.textColor = UIColor(named: "RepoTableViewCell.Text")
        desc.font = .systemFont(ofSize: 12)
        desc.snp.makeConstraints { (x) in
            x.left.equalTo(icon.snp.right).offset(12)
            x.right.equalTo(self.snp.right).offset(-12)
            x.top.equalTo(icon.snp.centerY).offset(6)
        }
        textView.isUserInteractionEnabled = false
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.snp.remakeConstraints { (x) in
            x.left.equalToSuperview().offset(28)
            x.right.equalToSuperview().offset(-28)
            x.top.equalToSuperview()
            x.bottom.equalToSuperview()
        }
        
        backgroundColor = .clear
        
    }
    
    func setIcon(withImage: UIImage?) {
        icon.image = withImage
    }
    
    func clearAll() {
        icon.image = nil
        name.text = nil
        desc.text = nil
        textView.text = nil
    }
    
    func setCondition(title: String, descriptionText: String, mets: Bool) {
        clearAll()
        if mets {
            icon.image = UIImage(named: "PKGVC.ok")
        } else {
            icon.image = UIImage(named: "PKGVC.error")
        }
        name.text = title
        desc.text = descriptionText
    }
    
    func setForPackageDescription(withPackage: PackageStruct, whenUpdateHeight: @escaping (_ height: CGFloat) -> ()) {
        clearAll()
        textView.text = "PackageDiagnosis_WelcomeLeft".localized() + " " + withPackage.obtainNameIfExists() + " " + "PackageDiagnosis_WelcomeRight".localized()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let size = self.textView.sizeThatFits(self.textView.frame.size)
            whenUpdateHeight(size.height)
        }
    }
    
    func setForDescription(withText: String, whenUpdateHeight: @escaping (_ height: CGFloat) -> ()) {
        clearAll()
        textView.text = withText
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let size = self.textView.sizeThatFits(self.textView.frame.size)
            whenUpdateHeight(size.height)
        }
    }
        
}
