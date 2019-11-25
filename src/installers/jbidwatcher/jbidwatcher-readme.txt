
Version History for 'jbidwatcher'
================================================

(March 18, 2012) —
JBidwatcher bumps up to 2.5, adds a first pass at scripting!

eBay related changes

    Better handle inter-country bidding failures, and some odd eBay interstitial pages
    Removed Dutch Auction support, since eBay doesn’t support that listing type anymore
    A ton of eBay-driven changes for new page formats, different bidding forms, and more.
    Better image/thumbnail retrieval, and price detection
    Improve BIN detection on fixed-price items you’ve already bought one of, multi-purchase buys, and underbid recognition.
    Fixed some snipe failures that were due to misinterpreting eBay’s broken HTML.
    Better ended-listing recognition

UI changes

    Add a ‘+’ tab for creating new tabs, to make it easier and more obvious
    Tweaked some minor UI inconsistencies
    Items move to their correct category after the fact, which looks a little odd, but means that items should end up in their appropriate categories without human intervention.
    Empty tabs have a little graphic in the middle; this will eventually get swapped out for some basic instructions, to make first-launch ramp-up time quicker.
    A bunch of (hopefully) improvements to the ‘first-run’ experience, including a simplified configuration screen.
    The ‘new update’ dialog got a makeover.
    Increased the default sizes on some dialogs, as monitor sizes have grown over the years
    Improve the thumbnail shown in ‘Show Info’.
    Focus should work better in all dialogs.

Internal fixes

    Fixed some My JBidwatcher setup/configuration issues
    Improved response to waking from sleep
    Internal improvements, reducing exceptions and deadlocks.
    Improve performance
    Some data-logging improvements
    Preserve some snipe information after a snipe has completed.
    Signing Mac binaries so JBidwatcher doesn’t get locked out by Mountain Lion

New features

    First pass at a multicast DNS service for wireless synch
    A purely opt-in metrics/analytics system so I can learn how folks use JBidwatcher in the wild.
    Brought back the scripting framework; JBidwatcher can now be scripted in JRuby

*The scripting framework is rudimentary right now, but I’m adding hooks as I touch code, and soon more of JBidwatcher will be implemented using JRuby.

JBidwatcher 2.x requires at least Java 1.5. This is available for Windows and Linux across the board, but it means that OS X 10.4 or later will be required for the Mac. I feel comfortable with two major versions back (So OS X 10.4 through 10.6, Java 1.5 and 1.6), as it combines the maximum number of people who will be able to use it, and a relatively usable development environment.

    Mac OS X users can download a a Mac OS X disk image (.dmg)
    Windows users can download a Windows installer. The standard 'download and run' executable is still available, of course.
    You can also download the Java binary for any other platform, including Linux and Solaris.
    Launch with:
    java -Xmx512m -jar JBidwatcher-2.5.jar


(October 1, 2011) —
JBidwatcher 2.1.6 has been released, resolving several eBay changes and bugs

It’s been a while since my last release, and eBay has made a few changes that caused searches and some other features to break. in the mean time I’ve been trying to add some small features and clean up the application some. 2.1.6 is the combination of these two things, along with a healthy amount of work in response to feedback during the long pre-release process. Best of luck with yourauctions!

User Visible

    Remove Mature Audiences from the eBay configuration display. It’s my #1 support problem for user having trouble logging in. It’s still accessible from the Advanced Configuration setting, as
    ‘ebay.mature’ (without the quotes), and it’s described in the FAQ.
    Fix a longstanding bug that you couldn’t really change username/password while running JBidwatcher; you had to shut it down and restart JBidwatcher. Now it takes effect immediately!
    Fix another longstanding bug where on a bid, JBidwatcher would forget who the seller was, replacing them with the high bidder’s id, and thus items would fall out of the selling tab.
    Some price detection improvements.
    Handle eBay’s new URL format.
    Don’t stomp on user-entered or previously-correctly detected shipping amounts.
    Sometimes updates would appear to stop, usually for newly added items, and items wouldn’t move to ‘complete’ after ending.
    Better handle the system tray on Windows with Java5.
    Drag an image onto a listing to replace its thumbnail with that image.
    Seller-ended auctions weren’t being recognized as ended.

Internals

    Hopefully improve sleep-detection and handling.
    Failing to load the tray.dll (as on Windows 7 64 bit) shouldn’t cause the program to fail to start up, and should fall back to Java6’s system tray code if possible.
    Lots of changes for debugging and testing.
    Improved scripting interface.
    Small improvements to thread safety.
    Lots of refactorings and cleanups.


