//
//  DSHSidebarViewController.m
//  DSH
//

#import "DSHSidebarViewController.h"
#import "DSHHarness.h"
#import "DSHKeepAlive.h"

typedef NS_ENUM(NSInteger, DSHSidebarSection) {
    DSHSidebarSectionStatus = 0,
    DSHSidebarSectionKeepAlive,
    DSHSidebarSectionTools,
    DSHSidebarSectionMaintenance,
};

@interface DSHSidebarViewController ()
@property (nonatomic, copy) NSDictionary<NSString *, void (^)(void)> *actions;
@property (nonatomic, strong) UISwitch *keepAliveSwitch;
@end

@implementation DSHSidebarViewController

- (instancetype)initWithActions:(NSDictionary<NSString *, void (^)(void)> *)actions {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _actions = [actions copy];
        self.title = @"DSH";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark.circle.fill"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(dismissSidebar)];
    self.navigationItem.rightBarButtonItem = close;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(harnessChanged)
                                                 name:DSHHarnessStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keepAliveChanged)
                                                 name:DSHKeepAliveDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)harnessChanged {
    NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:DSHSidebarSectionStatus];
    [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)keepAliveChanged {
    self.keepAliveSwitch.on = DSHKeepAlive.shared.isKeepAliveEnabled;
}

- (void)dismissSidebar {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case DSHSidebarSectionKeepAlive: return 1;
        case DSHSidebarSectionTools: return 5;
        case DSHSidebarSectionMaintenance: return 2;
        default: return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case DSHSidebarSectionStatus: return @"Status";
        case DSHSidebarSectionKeepAlive: return @"Instant Resume";
        case DSHSidebarSectionTools: return @"Tools";
        case DSHSidebarSectionMaintenance: return @"Maintenance";
        default: return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == DSHSidebarSectionKeepAlive) {
        return @"Plays a silent audio loop in the background so the Linux guest stays alive. Return to the app instantly, at the cost of a little battery.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *basic = @"DSHSidebarBasic";
    static NSString *value = @"DSHSidebarValue";
    UITableViewCell *cell;
    switch (indexPath.section) {
        case DSHSidebarSectionKeepAlive: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"DSHSidebarSwitch"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DSHSidebarSwitch"];
                UISwitch *sw = [[UISwitch alloc] init];
                [sw addTarget:self action:@selector(keepAliveToggled:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = sw;
                self.keepAliveSwitch = sw;
            }
            cell.textLabel.text = @"Keep guest alive";
            self.keepAliveSwitch.on = DSHKeepAlive.shared.isKeepAliveEnabled;
            return cell;
        }
        case DSHSidebarSectionStatus: {
            cell = [tableView dequeueReusableCellWithIdentifier:value];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:value];
            DSHHarnessState state = DSHHarness.shared.state;
            NSString *text;
            UIColor *color;
            switch (state) {
                case DSHHarnessStateReady:   text = @"Ready";       color = UIColor.systemGreenColor; break;
                case DSHHarnessStateFailed:  text = @"Failed";      color = UIColor.systemRedColor; break;
                case DSHHarnessStateStopped: text = @"Stopped";     color = UIColor.systemGrayColor; break;
                default:                     text = @"Starting…";   color = UIColor.systemOrangeColor; break;
            }
            cell.textLabel.text = @"Harness";
            // value 样式：右侧文字 + 状态色
            cell.detailTextLabel.text = text;
            cell.detailTextLabel.textColor = color;
            return cell;
        }
        default: {
            cell = [tableView dequeueReusableCellWithIdentifier:basic];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:basic];
            if (indexPath.section == DSHSidebarSectionTools) {
                cell.imageView.image = [UIImage systemImageNamed:@[@"arrow.clockwise", @"terminal", @"switch.2", @"list.bullet.rectangle", @"doc.text.magnifying"][indexPath.row]];
                cell.textLabel.text = @[@"Reload", @"Terminal", @"Capabilities", @"Activity", @"Server Log"][indexPath.row];
                cell.textLabel.textColor = UIColor.labelColor;
            } else {
                cell.imageView.image = [UIImage systemImageNamed:@[@"arrow.triangle.2.circlepath", @"wrench.and.screwdriver"][indexPath.row]];
                cell.textLabel.text = @[@"Restart Harness", @"Repair Linux Environment"][indexPath.row];
                cell.textLabel.textColor = UIColor.systemRedColor;
            }
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == DSHSidebarSectionTools) {
        NSString *keys[] = {@"reload", @"terminal", @"capabilities", @"activity", @"log"};
        void (^act)(void) = self.actions[keys[indexPath.row]];
        [self dismissViewControllerAnimated:YES completion:act];
    } else if (indexPath.section == DSHSidebarSectionMaintenance) {
        void (^act)(void) = self.actions[indexPath.row == 0 ? @"restart" : @"repair"];
        [self dismissViewControllerAnimated:YES completion:act];
    }
}

- (void)keepAliveToggled:(UISwitch *)sender {
    [DSHKeepAlive.shared setEnabled:sender.on];
}

@end
