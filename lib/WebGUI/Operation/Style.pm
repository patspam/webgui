package WebGUI::Operation::Style;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2002 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use Exporter;
use strict;
use Tie::CPHash;
use WebGUI::Form;
use WebGUI::International;
use WebGUI::Paginator;
use WebGUI::Privilege;
use WebGUI::Session;
use WebGUI::Shortcut;
use WebGUI::SQL;
use WebGUI::URL;
use WebGUI::Utility;

our @ISA = qw(Exporter);
our @EXPORT = qw(&www_copyStyle &www_addStyle &www_addStyleSave &www_deleteStyle &www_deleteStyleConfirm &www_editStyle &www_editStyleSave &www_listStyles);

#-------------------------------------------------------------------
sub www_addStyle {
        my ($output);
        if (WebGUI::Privilege::isInGroup(5)) {
                $output .= helpLink(16);
		$output .= '<h1>'.WebGUI::International::get(150).'</h1>';
		$output .= formHeader();
                $output .= WebGUI::Form::hidden("op","addStyleSave");
                $output .= '<table>';
                $output .= tableFormRow(WebGUI::International::get(151),WebGUI::Form::text("name",20,30));
                $output .= tableFormRow(WebGUI::International::get(152),WebGUI::Form::textArea("header",'',50,10));
                $output .= tableFormRow(WebGUI::International::get(153),WebGUI::Form::textArea("footer",'',50,10));
                $output .= tableFormRow(WebGUI::International::get(154),WebGUI::Form::textArea("styleSheet","<style>\n\n</style>",50,10));
                $output .= formSave();
                $output .= '</table>';
                $output .= '</form> ';
        } else {
                $output = WebGUI::Privilege::adminOnly();
        }
        return $output;
}

#-------------------------------------------------------------------
sub www_addStyleSave {
        my ($output);
        if (WebGUI::Privilege::isInGroup(5)) {
                WebGUI::SQL->write("insert into style values (".getNextId("styleId").", ".quote($session{form}{name}).", ".quote($session{form}{header}).", ".quote($session{form}{footer}).", ".quote($session{form}{styleSheet}).")");
                $output = www_listStyles();
        } else {
                $output = WebGUI::Privilege::adminOnly();
        }
        return $output;
}

#-------------------------------------------------------------------
sub www_copyStyle {
	my (%style);
        if (WebGUI::Privilege::isInGroup(5)) {
		%style = WebGUI::SQL->quickHash("select * from style where styleId=$session{form}{sid}");
                WebGUI::SQL->write("insert into style values (".getNextId("styleId").", ".quote('Copy of '.$style{name}).", ".quote($style{header}).", ".quote($style{footer}).", ".quote($style{styleSheet}).")");
                return www_listStyles();
        } else {
                return WebGUI::Privilege::adminOnly();
        }
}

#-------------------------------------------------------------------
sub www_deleteStyle {
        my ($output);
        if ($session{form}{sid} < 26 && $session{form}{sid} > 0) {
		return WebGUI::Privilege::vitalComponent();
        } elsif (WebGUI::Privilege::isInGroup(5)) {
                $output .= helpLink(4);
		$output .= '<h1>'.WebGUI::International::get(42).'</h1>';
                $output .= WebGUI::International::get(155).'<p>';
                $output .= '<div align="center"><a href="'.
			WebGUI::URL::page('op=deleteStyleConfirm&sid='.$session{form}{sid})
			.'">'.WebGUI::International::get(44).'</a>';
                $output .= '&nbsp;&nbsp;&nbsp;&nbsp;<a href="'.WebGUI::URL::page('op=listStyles').
			'">'.WebGUI::International::get(45).'</a></div>';
                return $output;
        } else {
                return WebGUI::Privilege::adminOnly();
        }
}

#-------------------------------------------------------------------
sub www_deleteStyleConfirm {
        if ($session{form}{sid} < 26 && $session{form}{sid} > 0) {
		return WebGUI::Privilege::vitalComponent();
        } elsif (WebGUI::Privilege::isInGroup(5)) {
                WebGUI::SQL->write("delete from style where styleId=".$session{form}{sid});
                WebGUI::SQL->write("update page set styleId=2 where styleId=".$session{form}{sid});
                return www_listStyles();
        } else {
                return WebGUI::Privilege::adminOnly();
        }
}

#-------------------------------------------------------------------
sub www_editStyle {
        my ($output, %style);
	tie %style, 'Tie::CPHash';
        if (WebGUI::Privilege::isInGroup(5)) {
                %style = WebGUI::SQL->quickHash("select * from style where styleId=$session{form}{sid}");
                $output .= helpLink(16);
		$output .= '<h1>'.WebGUI::International::get(156).'</h1>';
		$output .= formHeader();
                $output .= WebGUI::Form::hidden("op","editStyleSave");
                $output .= WebGUI::Form::hidden("sid",$session{form}{sid});
                $output .= '<table>';
		$output .= tableFormRow(WebGUI::International::get(380),$session{form}{sid});
                $output .= tableFormRow(WebGUI::International::get(151),WebGUI::Form::text("name",20,30,$style{name}));
                $output .= tableFormRow(WebGUI::International::get(152),WebGUI::Form::textArea("header",$style{header},50,10));
                $output .= tableFormRow(WebGUI::International::get(153),WebGUI::Form::textArea("footer",$style{footer},50,10));
                $output .= tableFormRow(WebGUI::International::get(154),WebGUI::Form::textArea("styleSheet",$style{styleSheet},50,10));
                $output .= formSave();
                $output .= '</table>';
                $output .= '</form> ';
        } else {
                $output = WebGUI::Privilege::adminOnly();
        }
        return $output;
}

#-------------------------------------------------------------------
sub www_editStyleSave {
        if (WebGUI::Privilege::isInGroup(5)) {
                WebGUI::SQL->write("update style set name=".quote($session{form}{name}).", header=".quote($session{form}{header}).", footer=".quote($session{form}{footer}).", styleSheet=".quote($session{form}{styleSheet})." where styleId=".$session{form}{sid});
                return www_listStyles();
        } else {
                return WebGUI::Privilege::adminOnly();
        }
}

#-------------------------------------------------------------------
sub www_listStyles {
        my ($output, $sth, @data, @row, $i, $p);
        if (WebGUI::Privilege::isInGroup(5)) {
                $output = helpLink(9);
		$output .= '<h1>'.WebGUI::International::get(157).'</h1>';
		$output .= '<div align="center"><a href="'.WebGUI::URL::page('op=addStyle').
			'">'.WebGUI::International::get(158).'</a></div>';
                $sth = WebGUI::SQL->read("select styleId,name from style where name<>'Reserved' order by name");
                while (@data = $sth->array) {
                        $row[$i] = '<tr><td valign="top" class="tableData"><a href="'.
				WebGUI::URL::page('op=deleteStyle&sid='.$data[0]).
				'"><img src="'.$session{setting}{lib}.'/delete.gif" border=0></a><a href="'.
				WebGUI::URL::page('op=editStyle&sid='.$data[0]).
				'"><img src="'.$session{setting}{lib}.'/edit.gif" border=0></a><a href="'.
				WebGUI::URL::page('op=copyStyle&sid='.$data[0]).
				'"><img src="'.$session{setting}{lib}.'/copy.gif" border=0></a></td>';
                        $row[$i] .= '<td valign="top" class="tableData">'.$data[1].'</td></tr>';
                        $i++;
                }
		$sth->finish;
		$p = WebGUI::Paginator->new(WebGUI::URL::page('op=listStyles'),\@row);
                $output .= '<table border=1 cellpadding=5 cellspacing=0 align="center">';
		$output .= $p->getPage($session{form}{pn});
		$output .= '</table>';
		$output .= $p->getBarTraditional($session{form}{pn});
                return $output;
        } else {
                return WebGUI::Privilege::adminOnly();
        }
}



1;
