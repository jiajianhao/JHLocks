//
//  ViewController.m
//  JHLocks
//
//  Created by admin on 2017/3/6.
//  Copyright © 2017年 jiajianhao. All rights reserved.
//  锁用来保证线程安全，防止数据同时访问处理导致数据脏掉；减少内存资源使用
//  单例中的锁，保证实例只有一个

#import "ViewController.h"
#import "TestLock.h"
#include <pthread.h>
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>{
    UITableView *myTableView;
    NSMutableArray *arrayForTypes;

}
@property(nonatomic,strong)TestLock*testLock;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBar.translucent=NO;
    self.view.backgroundColor=[UIColor whiteColor];
    
    
    arrayForTypes = [[NSMutableArray alloc]initWithObjects:@"NSLock",@"synchronized",@"gcd",@"pthread_mutex",nil];

    
    myTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, mWidth, mHeight) style:UITableViewStyleGrouped];
    myTableView.delegate=self;
    myTableView.dataSource=self;
    [myTableView setSectionIndexColor:UIColorFromRGB(0xFF5000)];
    [myTableView setSectionIndexBackgroundColor:[UIColor clearColor]];
    [myTableView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:myTableView];
    
    
    int a =302;
    int end1 =a;
    NSString *str=@"";
    while (end1!=1) {
        NSLog(@"%d",end1);
        int reminder = end1%2;
        str = [NSString stringWithFormat:@"%d%@",reminder,str];
        NSLog(@"%d",reminder);
        end1 = end1/2;
        
    }
    str = [NSString stringWithFormat:@"%d%@",1,str];
    NSLog(@"str: %@",str);

    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
//-(NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView{
//    return arrayForTypes;
//}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [arrayForTypes count];
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [arrayForTypes objectAtIndex:section];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString * identifier= @"cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    cell.backgroundColor = [UIColor clearColor];
    //自适应图片（大小）
    cell.textLabel.text = [arrayForTypes objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@"heart.png"];
    cell.detailTextLabel.text = [arrayForTypes objectAtIndex:indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   
    if(indexPath.row==0){
        [self nslockDemo];
    }
    if(indexPath.row==1){
        [self synchronizeDemo];
    }
    if(indexPath.row==2){
        [self gcdDemo];
    }
    if(indexPath.row==3){
        [self pthreadDemo];
    }

}
#pragma mark nslock
- (void)nslockDemo {
    NSLock *myLock = [[NSLock alloc] init];
    _testLock = [[TestLock alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [myLock lock];
        [_testLock method1];
        sleep(2);
        [myLock unlock];
        if ([myLock tryLock]) {
            NSLog(@"myLock 可以获得锁");
        }else {
            NSLog(@"myLock 不可以获得所");
        }
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        if ([myLock tryLock]) {
            NSLog(@"myLock---可以获得锁");
        }else {
            NSLog(@"myLock----不可以获得所");
        }
        [myLock lock];
        [_testLock method2];
        [myLock unlock];
    });
}

#pragma mark synchronize
- (void)synchronizeDemo {
    _testLock = [[TestLock alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (_testLock) {
            [_testLock method1];
            sleep(2);
        }
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        @synchronized (_testLock) {
            
            [_testLock method2];
        }
    });
}

#pragma mark GCD
- (void)gcdDemo {
    _testLock = [[TestLock alloc] init];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        [_testLock method1];
        sleep(2);
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(2);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        [_testLock method2];
        dispatch_semaphore_signal(semaphore);
    });
}

#pragma mark pthread
- (void)pthreadDemo {
    _testLock = [[TestLock alloc] init];
    
    __block pthread_mutex_t mutex;
    pthread_mutex_init(&mutex, NULL);
    
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        pthread_mutex_lock(&mutex);
        [_testLock method1];
        sleep(2);
        pthread_mutex_unlock(&mutex);
    });
    
    //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        pthread_mutex_lock(&mutex);
        [_testLock method2];
        pthread_mutex_unlock(&mutex);
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
