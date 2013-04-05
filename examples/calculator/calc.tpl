<html>
<head>
    <style>
        input \{
            width: 100%;
        \}
    </style>
</head>
<body>

<form method='post'>
<table border=1 cellspacing=0 cellpadding=0>
    <tr>
        <td colspan=4><input name='a' type='text' width='100%'></td>
    </tr>
    <tr>
        <td colspan=4><input name='b' type='text' width='100%'></td>
    </tr>
    <tr>
        <td>
            <input type='submit' name='action' value='+'>
        </td>
        <td>
            <input type='submit' name='action' value='-'>
        </td>
        <td>
            <input type='submit' name='action' value='*'>
        </td>
        <td>
            <input type='submit' name='action' value='/'>
        </td>
    </tr>
</table>
</form>
{$result}
{$OUT .= $m->blah(); }

</body>
</html>