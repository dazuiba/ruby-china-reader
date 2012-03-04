//
//  RCRTopicsViewController.m
//  RubyChinaReader
//
//  Created by James Chen on 3/3/12.
//  Copyright (c) 2012 ashchan.com. All rights reserved.
//

#import "RCRTopicsViewController.h"
#import "RCRTableRowView.h"
#import "RCRTopicCellView.h"
#import "RCRTopic.h"

@interface RCRTopicsViewController () {
    NSArray *_topics;
    NSMutableArray *_observedVisibleItems;
}

- (void)reloadRowForEntity:(id)object;
- (RCRTopic *)topicForRow:(NSInteger)row;

@end

@implementation RCRTopicsViewController

@synthesize topicsTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Topics";
        RKObjectMapping *topicMappping = [[RKObjectManager sharedManager].mappingProvider objectMappingForClass:[RCRTopic class]];
        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/api/topics.json" objectMapping:topicMappping delegate:self];
    }
    
    return self;
}

- (void)dealloc {
    [_topics release];
    [_observedVisibleItems release];
    [super dealloc];
}

#pragma mark - RKRequestDelegate

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
}

#pragma mark - RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
    [_topics release];
    _topics = [objects copy];
    [topicsTableView reloadData];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
}


#pragma mark - NSTableViewDelegate

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    RCRTableRowView *rowView = [[RCRTableRowView alloc] initWithFrame:NSMakeRect(0, 0, 300, 20)];
    rowView.objectValue = [self topicForRow:row];
    return [rowView autorelease];    
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    RCRTopic *topic = [self topicForRow:row];
    RCRTopicCellView *cellView = [topicsTableView makeViewWithIdentifier:@"TopicCell" owner:self];
    cellView.textField.stringValue = topic.title;
    cellView.nodeName.stringValue = topic.nodeName;
    cellView.repliesCount.stringValue = topic.repliesCount.stringValue;
    cellView.userName.stringValue = topic.user.login;
    
    if (_observedVisibleItems == nil) {
        _observedVisibleItems = [NSMutableArray new];
    }
    if (![_observedVisibleItems containsObject:topic.user]) {
        [topic addObserver:self forKeyPath:RCRTopicPropertyNamedGravatar options:0 context:NULL];
        [topic.user loadGravatar];
        [_observedVisibleItems addObject:topic.user];
    }
    
    if (topic.user.gravatar == nil) {
        [cellView.progressIndicator setHidden:NO];
        [cellView.progressIndicator startAnimation:nil];
        [cellView.imageView setHidden:YES];
    } else {
        [cellView.imageView setImage:topic.user.gravatar];
    }

    return cellView;
} 

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _topics.count;
}

#pragma mark - Private Methods & misc

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:RCRTopicPropertyNamedGravatar]) {
        [self performSelectorOnMainThread:@selector(reloadRowForEntity:) withObject:object waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    }
}

- (void)reloadRowForEntity:(id)object {
    NSInteger row = [_topics indexOfObject:object];
    if (row != NSNotFound) {
        RCRTopicCellView *cellView = [topicsTableView viewAtColumn:0 row:row makeIfNecessary:NO];
        if (cellView) {
            RCRTopic  *topic = [self topicForRow:row];
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:0.8];
            [cellView.imageView setAlphaValue:0];
            cellView.imageView.image = topic.user.gravatar;
            [cellView.imageView setHidden:NO];
            [[cellView.imageView animator] setAlphaValue:1.0];
            [cellView.progressIndicator setHidden:YES];
            [NSAnimationContext endGrouping];
        }
    }   
}

- (RCRTopic *)topicForRow:(NSInteger)row {
    return (RCRTopic *)[_topics objectAtIndex:row];
}

@end