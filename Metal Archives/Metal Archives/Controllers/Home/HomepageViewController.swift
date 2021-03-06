//
//  HomepageViewController.swift
//  Metal Archives
//
//  Created by Thanh-Nhon Nguyen on 12/01/2019.
//  Copyright © 2019 Thanh-Nhon Nguyen. All rights reserved.
//

import UIKit
import Toaster
import FirebaseAnalytics
import NotificationBannerSwift

final class HomepageViewController: RefreshableViewController {
    @IBOutlet private weak var searchButton: UIButton!
    
    private var statisticString: String?
    private var newsPagableManager = PagableManager<News>()
    private var bandAdditionPagableManager = PagableManager<BandAddition>()
    private var bandUpdatePagableManager = PagableManager<BandUpdate>()
    private var latestReviewPagableManager = PagableManager<LatestReview>()
    private var upcomingAlbumPagableManager = PagableManager<UpcomingAlbum>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Metal Archives"
        self.addToggleMenuButton()
        self.initSearchButton()
        self.loadHomepage()
        self.initObservers()
        self.alertNewVersion()
    }
    
    override func initAppearance() {
        super.initAppearance()

        //Hide 1st header
        self.tableView.contentInset = UIEdgeInsets(top: -CGFloat.leastNormalMagnitude, left: 0, bottom: 0, right: 0)
        
        LoadingTableViewCell.register(with: self.tableView)
        NewsTableViewCell.register(with: self.tableView)
        StatisticTableViewCell.register(with: self.tableView)
        BandAdditionOrUpdateTableViewCell.register(with: self.tableView)
        LatestReviewTableViewCell.register(with: self.tableView)
        UpcomingAlbumTableViewCell.register(with: self.tableView)
        ViewMoreTableViewCell.register(with: self.tableView)
    }
    
    private func initSearchButton() {
        self.searchButton.backgroundColor = Settings.currentTheme.backgroundColor
        self.searchButton.layer.shadowColor = Settings.currentTheme.bodyTextColor.cgColor
        self.searchButton.layer.shadowRadius = 10
        self.searchButton.layer.shadowOpacity = 0.5
        self.searchButton.layer.shadowOffset = CGSize(width: 2, height: 5)
        self.searchButton.layer.cornerRadius = self.searchButton.frame.height/2
        self.searchButton.layer.borderWidth = 0.2
        self.searchButton.layer.borderColor = Settings.currentTheme.bodyTextColor.withAlphaComponent(0.5).cgColor
    }
    
    private func initObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.OpenSearchModule, object: nil, queue: nil) { (notification) in
            self.didTapSearchButton()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.ShowBandDetail, object: nil, queue: nil) { (notification) in
            guard let bandURLString = notification.object as? String else {
                return
            }
            
            self.pushBandDetailViewController(urlString: bandURLString, animated: true)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.ShowReviewDetail, object: nil, queue: nil) { (notification) in
            guard let reviewURLString = notification.object as? String else {
                return
            }
            
            self.presentReviewController(urlString: reviewURLString, animated: true, completion: nil)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.ShowReleaseDetail, object: nil, queue: nil) { (notification) in
            guard let releaseURLString = notification.object as? String else {
                return
            }
            
            self.pushReleaseDetailViewController(urlString: releaseURLString, animated: true)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AskForReview, object: nil, queue: nil) { (notification) in
            self.gentlyAskForReview()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.navigationController?.isNavigationBarHidden ?? false
    }
    
    override func refresh() {
        self.statisticString = nil
        self.newsPagableManager.reset()
        self.bandAdditionPagableManager.reset()
        self.bandUpdatePagableManager.reset()
        self.latestReviewPagableManager.reset()
        self.upcomingAlbumPagableManager.reset()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.endRefreshing()
            self.loadHomepage()
        }
        
        Analytics.logEvent(AnalyticsEvent.RefreshHomepage, parameters: nil)
    }
    
    private func loadHomepage() {
        
        RequestHelper.HomePage.Statistic.fetchStats(onSuccess: { [weak self] (statisticString) in
            self?.statisticString = statisticString
            self?.tableView.reloadData()
        }) { (error) in
            
        }
        
        self.newsPagableManager.fetch { [weak self] (error) in
            self?.tableView.reloadData()
        }
        
        self.bandAdditionPagableManager = PagableManager<BandAddition>(options: ["<YEAR_MONTH>": monthList[0].requestParameterString])
        self.bandAdditionPagableManager.fetch { [weak self] (error) in
            self?.tableView.reloadData()
        }
        
        self.bandUpdatePagableManager = PagableManager<BandUpdate>(options: ["<YEAR_MONTH>": monthList[0].requestParameterString])
        self.bandUpdatePagableManager.fetch { [weak self] (error) in
            self?.tableView.reloadData()
        }
        
        self.latestReviewPagableManager =  PagableManager<LatestReview>(options: ["<YEAR_MONTH>": monthList[0].requestParameterString])
        self.latestReviewPagableManager.fetch { [weak self] (error) in
            self?.tableView.reloadData()
        }
        
        self.upcomingAlbumPagableManager.fetch { [weak self] (error) in
            self?.tableView.reloadData()
        }
    }
    
    @IBAction private func didTapSearchButton() {
        guard let searchViewController = UIStoryboard(name: "Search", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController else {
            return
        }
        
        self.navigationController?.pushViewController(searchViewController, animated: true)
    }
    
    private func gentlyAskForReview() {
        let alert = UIAlertController(title: "Hey", message: "It seems that you are enjoying the application, it's great! Please take 1 minute to leave a review on App Store.", preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "Okay! Take me to App Store!", style: .default) { (action) in
            openReviewOnAppStore()
            UserDefaults.setDidMakeAReview()
        }
        alert.addAction(okayAction)
        
        let cancelAction = UIAlertAction(title: "Remind me later", style: .cancel) { (action) in
            Analytics.logEvent(AnalyticsEvent.ReviewLatter, parameters: nil)
        }
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: - Segues
extension HomepageViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowLatestAdditions"{
            guard let latestAdditionsViewController = segue.destination as? LatestAdditionsOrUpdatesViewController else { return }
            latestAdditionsViewController.type = .additions
        } else if segue.identifier == "ShowLatestUpdates" {
            guard let latestAdditionsViewController = segue.destination as? LatestAdditionsOrUpdatesViewController else { return }
            latestAdditionsViewController.type = .updates
        }
    }
}

//MARK: - UITableViewDelegate
extension HomepageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        //Section: Stats
        case 0: self.didSelectRowInStatisticsSection(at: indexPath)
        //Section: News
        case 1: self.didSelectRowInNewsSection(at: indexPath)
        //Section: Latest additions
        case 2: self.didSelectRowInLatestAdditionsSection(at: indexPath)
        //Section: Latest updates
        case 3: self.didSelectRowInLatestUpdatesSection(at: indexPath)
        //Section: Latest reviews
        case 4: self.didSelectRowInLatestReviewsSection(at: indexPath)
        //Section: Upcoming albums
        case 5: self.didSelectRowInUpcomingAlbumsSection(at: indexPath)
        default: return
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        //Hide 1st section header
        if section == 0 {
            return CGFloat.leastNormalMagnitude
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = Settings.currentTheme.titleColor
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textColor = Settings.currentTheme.titleColor
        }
    }
}

//MARK: UITableViewDatasource
extension HomepageViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        //6 sections: Stats, News, Latest additions, Latest updates, Latest reviews, Upcoming albums
        return 6
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        //Section: Stats
        case 0: return self.numberOfRowsInStatisticsSection()
        //Section: News
        case 1: return self.numberOfRowsInNewsSection()
        //Section: Latest additions
        case 2: return self.numberOfRowsInLatestAdditionsSection()
        //Section: Latest updates
        case 3: return self.numberOfRowsInLatestUpdatesSection()
        //Section: Latest reviews
        case 4: return self.numberOfRowsInLatestReviewsSection()
        //Section: Upcoming albums
        case 5: return self.numberOfRowsInUpcomingAlbumsSection()
        default: fatalError("Impossible case!")
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        //Section: Stats
        case 0: return nil
        //Section: News
        case 1: return "NEWS"
        //Section: Latest additions
        case 2: return "LATEST ADDITIONS"
        //Section: Latest updates
        case 3: return "LATEST UPDATES"
        //Section: Latest reviews
        case 4: return "LATEST REVIEWS"
        //Section: Upcoming albums
        case 5: return "UPCOMING ALBUMS"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        //Section: Stats
        case 0: return self.cellForStatsSection(at: indexPath)
        //Section: News
        case 1: return self.cellForNewsSection(at: indexPath)
        //Section: Latets additions
        case 2: return self.cellForLatestAdditionsSection(at: indexPath)
        //Section: Latest updates
        case 3: return self.cellForLatestUpdatesSection(at: indexPath)
        //Section: Latest review
        case 4: return self.cellForLatestReviewsSection(at: indexPath)
        //Section: Upcoming albums
        case 5: return self.cellForUpcomingAlbumsSection(at: indexPath)
        default: return UITableViewCell()
        }
    }
}

//MARK: - View more cell
extension HomepageViewController {
    private func viewMoreCell(message: String, atIndex indexPath: IndexPath) -> ViewMoreTableViewCell {
        let cell = ViewMoreTableViewCell.dequeueFrom(self.tableView, forIndexPath: indexPath)
        cell.fill(message: message)
        return cell
    }
    
    private func loadingCell(atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = LoadingTableViewCell.dequeueFrom(self.tableView, forIndexPath: indexPath)
        cell.displayIsLoading()
        return cell
    }
}

//MARK: - Section STATISTICS
extension HomepageViewController {
    private func numberOfRowsInStatisticsSection() -> Int {
        return 1
    }
    
    private func cellForStatsSection(at indexPath: IndexPath) -> UITableViewCell {
        guard let `statisticString` = self.statisticString else {
            return self.loadingCell(atIndexPath: indexPath)
        }
        
        let cell = StatisticTableViewCell.dequeueFrom(self.tableView, forIndexPath: indexPath)
        cell.fill(with: statisticString)
        return cell
    }
    
    private func didSelectRowInStatisticsSection(at indexPath: IndexPath) {
        self.performSegue(withIdentifier: "ShowStatistics", sender: nil)
    }
}

//MARK: - Section NEWS
extension HomepageViewController {
    private func numberOfRowsInNewsSection() -> Int {
        return 1
    }
    
    private func cellForNewsSection(at indexPath: IndexPath) -> UITableViewCell {
        //Don't check totalRecords is nil or not because News doesn't have such parameter
        guard self.newsPagableManager.objects.count > 0 else {
            return self.loadingCell(atIndexPath: indexPath)
        }
        
        let cell = NewsTableViewCell.dequeueFrom(self.tableView, forIndexPath: indexPath)
        let news = self.newsPagableManager.objects[indexPath.row]
        cell.fill(with: news)
        return cell
    }
    
    private func didSelectRowInNewsSection(at indexPath: IndexPath) {
        let newsArchiveViewController = UIStoryboard(name: "NewsArchive", bundle: nil).instantiateViewController(withIdentifier: "NewsArchiveViewController" ) as! NewsArchiveViewController
        self.navigationController?.pushViewController(newsArchiveViewController, animated: true)
    }
}

//MARK: - Section LATEST ADDITIONS
extension HomepageViewController {
    private func numberOfRowsInLatestAdditionsSection() -> Int {
        guard let _ = self.bandAdditionPagableManager.totalRecords else {
            return 1
        }
        
        if self.bandUpdatePagableManager.objects.count > Settings.shortListDisplayCount {
            return Settings.shortListDisplayCount + 1
        }
        
        return self.bandAdditionPagableManager.objects.count + 1
    }
    
    private func cellForLatestAdditionsSection(at indexPath: IndexPath) -> UITableViewCell {
        guard let _ = self.bandAdditionPagableManager.totalRecords else {
            return self.loadingCell(atIndexPath: indexPath)
        }
        
        if indexPath.row == Settings.shortListDisplayCount || indexPath.row == self.bandAdditionPagableManager.objects.count {
            return self.viewMoreCell(message: "More latest additions", atIndex: indexPath)
        }
        
        let cell = BandAdditionOrUpdateTableViewCell.dequeueFrom(self.tableView, forIndexPath: indexPath)
        
        let band = self.bandAdditionPagableManager.objects[indexPath.row]
        cell.fill(with: band)
        
        return cell
    }
    
    private func didSelectRowInLatestAdditionsSection(at indexPath: IndexPath) {
        guard let _ = self.bandAdditionPagableManager.totalRecords else {
            return
        }
        
        if indexPath.row == Settings.shortListDisplayCount || indexPath.row == self.bandAdditionPagableManager.objects.count  {
            self.didSelectBandLatestAddtionsViewMore()
            return
        }
        
        let selectedBand = self.bandAdditionPagableManager.objects[indexPath.row]
        self.pushBandDetailViewController(urlString: selectedBand.urlString, animated: true)
        
        Analytics.logEvent(AnalyticsEvent.SelectAnItemInHomepage, parameters: [AnalyticsParameter.ItemType: "BandAddition"])
    }
    
    private func didSelectBandLatestAddtionsViewMore() {
        self.performSegue(withIdentifier: "ShowLatestAdditions", sender: nil)
        
        Analytics.logEvent(AnalyticsEvent.SelectAnItemInHomepage, parameters: [AnalyticsParameter.ItemType: "Show more latest additions"])
    }
}

//MARK: - Section LATEST UPDATES
extension HomepageViewController {
    private func numberOfRowsInLatestUpdatesSection() -> Int {
        guard let _ = self.bandUpdatePagableManager.totalRecords else {
            return 1
        }
        
        if self.bandUpdatePagableManager.objects.count > Settings.shortListDisplayCount {
            return Settings.shortListDisplayCount + 1
        }
        
        return self.bandUpdatePagableManager.objects.count + 1
    }
    
    private func cellForLatestUpdatesSection(at indexPath: IndexPath) -> UITableViewCell {
        guard let _ = self.bandUpdatePagableManager.totalRecords else {
            return self.loadingCell(atIndexPath: indexPath)
        }
        
        if indexPath.row == Settings.shortListDisplayCount || indexPath.row == self.bandUpdatePagableManager.objects.count  {
            return self.viewMoreCell(message: "More latest updates", atIndex: indexPath)
        }
        
        let cell = BandAdditionOrUpdateTableViewCell.dequeueFrom(self.tableView, forIndexPath: indexPath)
        
        let band = self.bandUpdatePagableManager.objects[indexPath.row]
        cell.fill(with: band)
        
        return cell
    }
    
    private func didSelectRowInLatestUpdatesSection(at indexPath: IndexPath) {
        guard let _ = self.bandUpdatePagableManager.totalRecords else {
            return
        }
        
        if indexPath.row == Settings.shortListDisplayCount || indexPath.row == self.bandUpdatePagableManager.objects.count  {
            self.didSelectBandLatestUpdatesViewMore()
            return
        }
        
        let selectedBand = self.bandUpdatePagableManager.objects[indexPath.row]
        self.pushBandDetailViewController(urlString: selectedBand.urlString, animated: true)
        
        Analytics.logEvent(AnalyticsEvent.SelectAnItemInHomepage, parameters: [AnalyticsParameter.ItemType: "BandUpdate"])
    }
    
    private func didSelectBandLatestUpdatesViewMore() {
        self.performSegue(withIdentifier: "ShowLatestUpdates", sender: nil)
        
        Analytics.logEvent(AnalyticsEvent.SelectAnItemInHomepage, parameters: [AnalyticsParameter.ItemType: "Show more latest updates"])
    }
}

//MARK: - Section LATEST REVIEWS
extension HomepageViewController {
    private func numberOfRowsInLatestReviewsSection() -> Int {
        guard let _ = self.latestReviewPagableManager.totalRecords else {
            return 1
        }
        
        if self.latestReviewPagableManager.objects.count > Settings.shortListDisplayCount {
            return Settings.shortListDisplayCount + 1
        }
        
        return self.latestReviewPagableManager.objects.count + 1
    }
    
    private func cellForLatestReviewsSection(at indexPath: IndexPath) -> UITableViewCell {
        guard let _ = self.latestReviewPagableManager.totalRecords else {
            return self.loadingCell(atIndexPath: indexPath)
        }
        
        if indexPath.row == Settings.shortListDisplayCount || indexPath.row == self.latestReviewPagableManager.objects.count {
            return self.viewMoreCell(message: "More latest reviews", atIndex: indexPath)
        }
        
        let cell = LatestReviewTableViewCell.dequeueFrom(self.tableView, forIndexPath: indexPath)
        
        let latestReview = self.latestReviewPagableManager.objects[indexPath.row]
        cell.fill(with: latestReview)
        
        return cell
    }
    
    private func didSelectRowInLatestReviewsSection(at indexPath: IndexPath) {
        guard let _ = self.latestReviewPagableManager.totalRecords else {
            return
        }
        
        if indexPath.row == Settings.shortListDisplayCount || indexPath.row == self.latestReviewPagableManager.objects.count {
            self.didSelectLatestReviewsViewMore()
            return
        }
        
        let latestReview = self.latestReviewPagableManager.objects[indexPath.row]
        self.takeActionFor(actionableObject: latestReview)
        
        Analytics.logEvent(AnalyticsEvent.SelectAnItemInHomepage, parameters: [AnalyticsParameter.ItemType: "LatestReview"])
    }
    
    private func didSelectLatestReviewsViewMore() {
        self.performSegue(withIdentifier: "ShowLatestReviews", sender: nil)
        
        Analytics.logEvent(AnalyticsEvent.SelectAnItemInHomepage, parameters: [AnalyticsParameter.ItemType: "Show more latest reviews"])
    }
}

//MARK: - Section UPCOMING ALBUMS
extension HomepageViewController {
    private func numberOfRowsInUpcomingAlbumsSection() -> Int {
        guard let _ = self.upcomingAlbumPagableManager.totalRecords else {
            return 1
        }
        
        if self.upcomingAlbumPagableManager.objects.count > Settings.shortListDisplayCount {
            return Settings.shortListDisplayCount + 1
        }
        
        return self.upcomingAlbumPagableManager.objects.count + 1
    }
    
    private func cellForUpcomingAlbumsSection(at indexPath: IndexPath) -> UITableViewCell {
        guard let _ = self.upcomingAlbumPagableManager.totalRecords else {
            return self.loadingCell(atIndexPath: indexPath)
        }
        
        if indexPath.row == Settings.shortListDisplayCount || indexPath.row == self.upcomingAlbumPagableManager.objects.count {
            return self.viewMoreCell(message: "More upcoming albums", atIndex: indexPath)
        }
        
        let cell = UpcomingAlbumTableViewCell.dequeueFrom(self.tableView, forIndexPath: indexPath)
        
        let upcomingAlbum = self.upcomingAlbumPagableManager.objects[indexPath.row]
        cell.fill(with: upcomingAlbum)
        
        return cell
    }
    
    private func didSelectRowInUpcomingAlbumsSection(at indexPath: IndexPath) {
        guard let _ = self.upcomingAlbumPagableManager.totalRecords else {
            return
        }
        
        if indexPath.row == Settings.shortListDisplayCount || indexPath.row == self.upcomingAlbumPagableManager.objects.count {
            self.didSelectUpcomingAlbumsViewMore()
            return
        }
        
        let upcomingAlbum = self.upcomingAlbumPagableManager.objects[indexPath.row]
        self.takeActionFor(actionableObject: upcomingAlbum)
        
        Analytics.logEvent(AnalyticsEvent.SelectAnItemInHomepage, parameters: [AnalyticsParameter.ItemType: "UpcomingAlbum"])
    }
    
    private func didSelectUpcomingAlbumsViewMore() {
        self.performSegue(withIdentifier: "ShowUpcomingAlbums", sender: nil)
        
        Analytics.logEvent(AnalyticsEvent.SelectAnItemInHomepage, parameters: [AnalyticsParameter.ItemType: "Show more upcoming albums"])
    }
}

//MARK: - Alert new version
extension HomepageViewController {
    private func alertNewVersion() {
        guard UserDefaults.shouldAlertNewVersion() else {
            return
        }
        
        guard let url = Bundle.main.url(forResource: "VersionHistory", withExtension: "plist") else  {
            assertionFailure("Error loading list of version history. File not found.")
            return
        }
        
        guard let array = NSArray(contentsOf: url) as? [[String: String]] else {
            assertionFailure("Error loading list of version history. Unknown format.")
            return
        }
        
        guard let number = array[0]["number"], let features = array[0]["features"] else {
            return
        }
    
        let banner =
            GrowingNotificationBanner(title: "Congratulation!\nYou are on a new version of Metal Archives iOS!", subtitle: "What's new in this v\(number):\n\(features)\n\nA version history is also available in About section.", leftView: nil, rightView: nil, style: .info, colors: nil, iconPosition: .top)
        banner.autoDismiss = false
        banner.dismissOnTap = true
        banner.show()
        UserDefaults.markDidAlertNewVersion()
    }
}
