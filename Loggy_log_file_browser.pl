#!/usr/bin/env perl


#############################################################################################
## This software can be used for personal and commercial use.                              ##
## Please do not remove this message when modifying and/or distributing.                   ##
## The main copy of this software is located at:                                           ##
##   https://github.com/worldorder2013/Loggy/blob/main/Loggy_log_file_browser.pl           ##
## Any alterations from the main code is solely at the user's liabilities                  ## 
## I am not liable for any damage which occurs with the use of this software.              ##
## Author: Richmond Kerville Magallon                                                      ##
## Email me for questions, suggestions, and bugs at: hastyt627@gmail.com                   ##
#############################################################################################

use Tk 800.000;
use Tk::HList;
use Tk::LabEntry;
use Tk::DialogBox;
use Tk::Dialog;
use Tk::Tree;
use Tk::Adjuster;
use Tk::ItemStyle;
use File::Spec;
use strict;

## global variables
my %ERRORS;
my %WARNINGS;
my %MSG;
my %OPTIONS;
my %WAIVED;
my $filename;
my $latest_file_pattern="*.log[0-9]*";
my $tool = "Innovus";
my $tools_ = [['Innovus', "Innovus"], ['ICC2', "ICC2"], ['Tempus', "Tempus"]];
my $preferences_file = "$ENV{HOME}/log_browser_preferences.txt";
my $wrap_text_mode = "word";
my %PREFS = (
	tool => $tool,
	latest_file_pattern => $latest_file_pattern,
	wrap_text_mode => $wrap_text_mode,
	
);

&process_args();
$preferences_file = $OPTIONS{preferences_file} if ($OPTIONS{preferences_file} ne '');

if (&check_preferences_file_status()>0){
	&process_preferences_file();
}elsif (&check_preferences_file_status()<0){
	&create_init_preferences_file();
}else{
	##Do nothing. Use default hard coded value.
}

# GUI Tk starts here
my $top = MainWindow->new();
$top->title("Loggy - $PREFS{tool}");
$top->configure(-width => 300); 
$top->configure(-background => 'Snow1'); 

## Menu GUI
#my $menu = $top->Menu;
$top->configure(-menu => my $menubar = $top->Menu);
$menubar->configure(-background=>"PaleGoldenRod"); 
$menubar->configure(-fg=>"Red3"); 
$menubar->configure(-activeforeground=>"Red3"); 
$menubar->configure(-activebackground=>"White"); 
$menubar->configure(-activeborderwidth=>0); 
my $file = $menubar->cascade(-label => '~File', -tearoff=>0); 
my $edit = $menubar->cascade(-label => '~Edit', -tearoff=>0); 
my $waive = $menubar->cascade(-label => '~Waive', -tearoff=>0); 
my $help = $menubar->cascade(-label => '~Help', -tearoff=>0); 

#$file->configure(-background=>"Snow1"); 
#$edit->configure(-background=>"Snow1"); 
#$help->configure(-background=>"Snow1"); 


my $mfont = "Arial 9";
my $newfile = $file->cascade(
	-label => 'Choose Tool',
	-underline => 0,
	-tearoff => 0,
	-background=>'White',
	-activebackground=>"white",
	-font=>"$mfont"

);
$file->command(
	-label => 'Open',
	-underline => 0,
	-command => \&open_file,
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"

);
$file->command(
	-label => 'Open Latest',
	-underline => 0,
	-command => \&open_auto_log_file,
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"

);
$file->command(
	-label => 'Save Messages (All)',
	-underline => 0,
	-command => [\&save_messages, "all"],
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"

);
$file->command(
	-label => 'Save Messages (Summarized)',
	-underline => 0,
	-command => [\&save_messages, "summarized"],
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"
);


foreach (@$tools_){
	$newfile->radiobutton(
        	-label => $_->[0],
        	-variable => \$PREFS{tool},
        	-value =>  $_->[1],
		-command => \&update_tool,
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"
	
	);
}

$edit->command(-label => "'Latest File' Pattern", 
-command => \&open_dialog,
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"
);
my $wrap_opt = $edit->cascade(-label => "Wrap Text", 
-tearoff=>0,
-command => \&wrap_text,
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"
);
my $wrap_option = [["Enable", "word"], ["None", "none"]];
foreach (@$wrap_option){
	$wrap_opt->radiobutton(
        	-label => $_->[0],
        	-variable => \$PREFS{wrap_text_mode},
        	-value =>  $_->[1],
		-command => \&wrap_text,
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"
	
	);
}

## Waive Sub-Menu Section
$waive->command(
	-label => 'Load',
	-underline => 0,
	-command => [\&open_waive_file, "new"],
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"

);
$waive->command(
	-label => 'Load last file',
	-underline => 0,
	-command => [\&open_waive_file, "previous"],
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"

);
$waive->command(
	-label => 'Save New',
	-underline => 0,
	-command => [\&save_waiver, "new"],
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"

);
$waive->command(
	-label => 'Save Update',
	-underline => 0,
	-command => [\&save_waiver, "update"],
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"

);

## Help Sub-Menu Section
$help->command(-label => 'Loggy Log File Browser v1.0',
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"
);
$help->command(-label => 'Author: RK*MaG',
	-background=>"white",
	-activebackground=>"white",
	-font=>"$mfont"
);
my $fr = $top->Frame(-width => 150, -height => 500);
$fr->configure(-background => 'Green');
my $l = $fr->Label(-text => 'Log Browser', -anchor => 'n',
	-relief => 'groove',-width => 10, -height => '3');
my $l_bottom = $top->Label(-text => "No log file selected",
	-anchor => 'n', -relief => 'groove', -height => '1');

$l_bottom->configure(-background=>'White');
$l_bottom->configure(-border=>0);
$l_bottom->configure(-font=>"Arial 9");

my $hlist = $top->Scrolled('Tree', -selectmode => 'extended', -indent => 10, -drawbranch => 1, -scrollbars => "osw"); 
$hlist->add("Errors", -text => "Errors"); 
$hlist->add("Warnings", -text => "Warnings"); 
$hlist->add("Information", -text => "Info"); 
$hlist->configure(-width=>22);
$hlist->configure(-height=>30);
$hlist->configure(-font=>'Arial 8 bold');
$hlist->configure(-border=>0);
$hlist->configure(-selectbackground=>'MistyRose1');
$hlist->configure(-highlightcolor=>"MistyRose1"); 
$hlist->configure(-background=>'White');
$hlist->configure(-command=>\&cb_populate_warning_error_textfield);
$hlist->configure(-browsecmd=>\&cb_multi_populate_warning_error_textfield);
$hlist->Subwidget("yscrollbar")->configure(-width=> 10);
$hlist->Subwidget("yscrollbar")->configure(-borderwidth=> 2);
$hlist->Subwidget("xscrollbar")->configure(-width=> 10);
$hlist->autosetmode();




## Item Styles ##
my $waived_text = $top->ItemStyle('text', -bg=>'white', -foreground => 'gray', -selectforeground => 'gray', -font => 'Arial 8 bold'); 

##Context Menu

my $m = $hlist->Menu(-tearoff => 0,-title=>'None',
  -menuitems =>
    [
     [Button => "Waive",  -command => \&cm_process_waived],
     [Button => "Un-waive",  -command => \&cm_process_dewaive],
    ]
   );

$hlist->bind("<Button-3>" => [ sub {
                              $hlist->focus; # focus on listbox widget 
                              my($w, $x, $y) = @_;
                              $m->post($x, $y);
                                 }, Ev('X'), Ev('Y') ] );
$m->bind("<Leave>"=>sub{$m->unpost});

## text Gui
my $text = $fr->Scrolled("Text", -background => 'white', -scrollbars => 'osoe');
$text->configure(-wrap=>$PREFS{wrap_text_mode});
$text->configure(-height => 30);
$text->configure(-width => 150);
$text->Subwidget("yscrollbar")->configure(-relief=> 'flat');
$text->Subwidget("yscrollbar")->configure(-borderwidth=> 2);
$text->Subwidget("xscrollbar")->configure(-relief=> 'flat');

## Geometry management
$hlist->pack(-side=>'left', -anchor=>'n', -fill=>'y');
$top->Adjuster()->packAfter($hlist, -side => 'left');
$text->pack(-side=>'right', -anchor=>'e', -fill=> 'both', -expand => 1);
$fr->pack(-expand => 1, -side=>'top', -anchor=>'w', -fill=>'both');
$l_bottom->pack(-side => "bottom", -fill=>'x');

## Main loop
MainLoop();


## Sub-routines
sub open_file {
	my $types = [
    	['log Files',       ['*.log*']],
    	['All Files',        '*',             ],
	];
	my $h=$top->getOpenFile(-filetypes=>$types);
	if ($h eq ""){
		return;	
	}else{
		&clear_message_textfield();
		&process_log_file($h);
	}
	
}

sub open_auto_log_file {
	my @log_files=glob($PREFS{latest_file_pattern});
	my $file_epoch;
	my $final_file = $log_files[0];
	my $file_epoch_max = (stat($log_files[0]))[9];
	foreach (@log_files){
		$file_epoch = (stat($_))[9];
		if ($file_epoch>=$file_epoch_max){
			$file_epoch_max = $file_epoch;
			$final_file = $_; 
		}
	}
	$final_file = File::Spec->rel2abs($final_file);
	&clear_message_textfield();
	&process_log_file($final_file);

}

sub open_dialog{
	my $temp = $PREFS{latest_file_pattern};
	my $dd=$top->DialogBox(-title=>"Enter Pattern", -buttons=>["OK", "Cancel"]);
	$dd->add('LabEntry', -textvariable => \$PREFS{latest_file_pattern}, -width=>20, -label=>"Pattern:",
	-labelPack => [-side => 'left'])->pack;
	my $mm = $dd->Show();
	if  ($mm eq "OK") {
		&update_preferences_file();

	}else{
		$PREFS{latest_file_pattern} = $temp;
	}
}

sub process_log_file {
	our $h = shift @_;
	our $mode = shift @_;
	&clear_hlist_entries;
	&clear_messages_variable;
	if (! (-f  $h && -T _)){
		my $DialogRef = $top->Dialog(
    		-title => "Error",
    		-text => "File '$h' is not readable.",
		)->Show();
		$l_bottom->configure(-text=>"Invalid file opened!" );
		return 0;
	}
	if ($PREFS{tool} eq "Innovus"){
		&parse_error_warn_innovus($h);
	}
	&populate_hlist_entries;
	$hlist->autosetmode();

	my $file_mod_time = localtime((stat($h))[9]);
	$l_bottom->configure(-text=>"$h $file_mod_time" );
}


sub parse_error_warn_innovus {
	$filename = shift @_;
	open(FH, "<$filename");
	# or die "Couldn't open file $filename: $!";
	while (<FH>) {
		chomp $_;
		if (/\*\*ERROR: \((\S+)\)/){
			push (@{$MSG{Errors}{$1}}, $_);
		}
		if (/\*\*WARN: \((\S+)\)/){
			push (@{$MSG{Warnings}{$1}}, $_);
		}
		if (/\*\* INFO: (.*)/){
			push (@{$MSG{Information}{"INFO"}}, $_);
		}
	}
	close FH;
}

sub populate_hlist_entries {
	my $num_msg;
	foreach my $msgtype (keys %MSG) {
		foreach (sort keys %{$MSG{$msgtype}}){
			$num_msg = scalar( @{$MSG{$msgtype}{$_}});
			if ($WAIVED{quotemeta($_)}){
			$hlist->add("${msgtype}.$_", -text => "$_ ($num_msg)", -style=>$waived_text, -itemtype=>'text'); 
			} else {
			$hlist->add("${msgtype}.$_", -text => "$_ ($num_msg)"); 
			}
		
		}
	} 
}

sub clear_hlist_entries {
	foreach ( keys %MSG){
		$hlist->delete('offsprings', $_) if $hlist->info('exists', $_);
	}
}
sub clear_messages_variable {
	%MSG=undef;
}

sub clear_message_textfield{
        $text->selectAll;
        $text->deleteSelected;
}


sub save_messages {
	my $mode = shift @_;
	our $h=$top->getSaveFile();
	open FH, ">$h";
	our $num_msg;
	foreach my $msgtype (keys %MSG) {
		next if $msgtype=~/^$/;
		print FH "------$msgtype------\n";
		foreach my $msgs ( keys %{$MSG{$msgtype}}){
			$num_msg = scalar( @{$MSG{$msgtype}{$msgs}});
			print FH "$msgs (Total of $num_msg):\n";
			
			if ($mode eq "all"){
				foreach my $lines (@{$MSG{$msgtype}{$msgs}}){
					print FH "$lines\n";
				}
			}elsif ($mode eq "summarized"){
				if ($msgs eq "Info"){
					my $sticky;
					foreach my $inf (sort {$a<=>$b} @{$MSG{$msgtype}{$msgs}}){
						if ($inf eq $sticky){
							next;
						}else{
							print FH "$inf\n";
							$sticky = $inf;
						}
					} 
				}else{
					print FH "$MSG{$msgtype}{$msgs}->[0]\n"; 
				}
			}
		
		}
		print FH "\n"; 
	}
	close FH;
}


sub waiver_filter {
return 0
}


sub cb_populate_warning_error_textfield {
	my ($widget , $mode) = @_;
	my ($msg_type, $msg_code) = split(/\./,$widget);
	$text->selectAll;
	$text->deleteSelected;
	if ( $msg_code eq ""){
		foreach (sort keys %{$MSG{$msg_type}}){
			$text->insert('end', "$_\n");
			$text->insert('end', "$MSG{$msg_type}{$_}->[0]\n");
			$text->insert('end', "\n");
		}
		return;
	}
	foreach ( @{$MSG{$msg_type}{$msg_code}}){
		$text->insert('end', "$_\n");
	}
}
sub cb_multi_populate_warning_error_textfield {
	my ($widget , $mode) = @_;
	$text->selectAll;
	$text->deleteSelected;
	foreach $widget ($hlist->info('selection')){
		my ($msg_type, $msg_code) = split(/\./,$widget);
		if ( $msg_code eq ""){
			foreach (sort keys %{$MSG{$msg_type}}){
				$text->insert('end', "$_\n");
			}
			next;
		}
		foreach ( @{$MSG{$msg_type}{$msg_code}}){
			$text->insert('end', "$_\n");
		}
	}
}

sub check_preferences_file_status {
	if ( -e $preferences_file ) {
		return 1;
	} elsif (-w $ENV{HOME}) {
		return -1;	
	} else {
		return 0
	}
}

sub process_preferences_file {
	open(FH, "< $preferences_file");
	foreach (<FH>){
		my ($variable, $value) = split(/:/);
		$variable =~ s/^\s+//g;
		$variable =~ s/\s+$//g;
		$value =~ s/^\s+//g;
		$value =~ s/\s+$//g;
		$PREFS{$variable}=$value;
	}
	close FH;


}

sub update_preferences_file {
	return 0 if (&check_preferences_file_status == 0);
	open(FH, "> $preferences_file");
	foreach (keys %PREFS){
		print FH "$_ : $PREFS{$_}\n";
	}
	close FH;
}

sub update_tool {
	$top->configure(-title => "Loggy - $PREFS{tool}"),
	&update_preferences_file();
}

sub create_init_preferences_file {
	open FH, "> $preferences_file";
	foreach (keys %PREFS){
		print FH "$_ : $PREFS{$_}\n";
	}
	close FH;
}

sub wrap_text {
	if ($PREFS{wrap_text_mode} eq "word") {
		$text->configure(-wrap=>'word');
	}else { 
		$text->configure(-wrap=>'none');
	}
	&update_preferences_file();
}


sub process_args {
	foreach (@ARGV){
		if (/-(\S+=\S+)/){
			my ($option, $pvalue) = split(/=/,$1);
			$OPTIONS{$option} = $pvalue;
		}
	}
}


sub open_waive_file {
	my $mode = shift @_;
	my $h;
	if ($mode eq 'previous'){
		$h = $PREFS{last_waiver_file};
	} elsif ($mode eq 'new'){
		my $types = [
    		['Waive Files',       ['*.waive*']],
    		['All Files',        '*',             ],
		];
		$h=$top->getOpenFile(-filetypes=>$types);
		if ($h eq ""){
			return;	
		} elsif  (! (-f  $h && -T _)){
			my $DialogRef = $top->Dialog(
    			-title => "Error",
    			-text => "File '$h' is not readable.",
			)->Show();
			$l_bottom->configure(-text=>"Invalid waiver file opened!" );
		return 0;
	}	
		$PREFS{last_waiver_file} = File::Spec->rel2abs($h);
		&update_preferences_file();
	}
	&process_waive_file($h);
	&clear_hlist_entries();
	&populate_hlist_entries();
	
}

sub process_waive_file {
	my $h = shift @_;
	open FH, "< $h";
	foreach (<FH>){
		chomp;
		$WAIVED{$_} = 1;
	}
}

sub cm_process_waived {
foreach  ($hlist->info('selection')) {
	/^[^.]+?\.([^.]+?)$/;
	my $selection_head = $1;
	&store_waived($selection_head);
	&clear_hlist_entries();
	&populate_hlist_entries();
}

}
sub cm_process_dewaive {
foreach  ($hlist->info('selection')) {
	/^[^.]+?\.([^.]+?)$/;
	my $selection_head = $1;
	delete $WAIVED{quotemeta($selection_head)};
	&clear_hlist_entries();
	&populate_hlist_entries();
}

}

sub store_waived {
	my $waived_head = shift @_;
	my $waived_content = shift @_;
	my $waived_head_q = quotemeta $waived_head;
	my $waived_content_q;
	$waived_content_q = quotemeta $waived_content if $waived_content ne "";
		#push (@{$WAIVED{$waived_head_q}}, $waived_content_q);
		$WAIVED{$waived_head_q}=1;
}

sub save_waiver {
	my $mode = shift @_;
	my $h;
	if ($mode eq "update"){
		$h = $PREFS{last_waiver_file};
	 }elsif($mode eq "new"){
	$h=$top->getSaveFile();
	return 0 if $h eq '';
	$PREFS{last_waiver_file} = $h;
	}
	open FH, ">$h";
	my $num_msg;
	foreach (keys %WAIVED){
		print FH "$_\n";
	}
	close FH;
}
