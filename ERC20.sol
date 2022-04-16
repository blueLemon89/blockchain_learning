// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;    // Sử dụng solidity v0.8.0


interface IERC20 {
    //Tạo hàm totalSupply trả về số token tồn tại
    function totalSupply() external view returns (uint256);

     //Tạo hàm balanceOf trả về số token được sở hữu bởi 'acount'
    function balanceOf(address account) external view returns (uint256);

     // Kiểm tra việc chuyển 'amount' token từ caller's account sang recipient có thành công hay không
    function transfer(address recipient, uint256 amount) external returns (bool);

    //Tạo hàm allowance trả về số token còn lại mà 'spender' sẽ được phép sử dụng thay mặt cho 'owner' 
    //thông qua 'Tranferform'. Giá trị mặc định bằng 0
    function allowance(address owner, address spender) external view returns (uint256);

     // Kiểm tra việc 'amount' token có được chuyển thành allowance cho spender hay không
    function approve(address spender, uint256 amount) external returns (bool);

    //Kiểm tra việc chuyển 'amount' token từ 'sender' sang 'recipient' bằng cách sử dụng cơ chế allowance.
    //thành công hay không
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    // Thực hiện 1 event khi 'value' token được chuyển từ 1 account 'from' sang account 'to'
    event Transfer(address indexed from, address indexed to, uint256 value);

    // thực hiện 1 event khi allownace của 'spender' cho 'owner' được xét thành công thông qua hàm 'approve'.
    // value là 1 allowance mới
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Tạo 1 interface IERC20Metadata là 1 interface trung gian của IERC20
 interface IERC20Metadata is IERC20 {
     // Tạo hàm name() trả về tên của token
    function name() external view returns (string memory);

    // Tạo hàm symbol() để trả về biểu tượng của token
    function symbol() external view returns (string memory);

    // Tạo hàm decimals() để trả về số số đứng sau dấu phẩy của 1 token
    function decimals() external view returns (uint8);
}

// Tạo 1 abstract Contract làm contract cơ sở để các contract khác kế thừa
abstract contract Context {
    // Cung cấp thông tin về 'execution context' hiện tại, bao gồm 'sender' và 'data' của giao dịch 
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    // Q: Tại sao không sử dụng trực tiếp thông qua msg.sender và msg.data ?
    // A: khi xử lí giao dịch thì tài khoản gửi và nhận có thể không phải người gửi/nhận thực sự

    //P/s: Là bắt buộc với các hợp đồng trung gian (Giống thư viện)
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances; // key = address, val = unit256

    //  address1 có thể tài trợ address2 1 số token(uint) nhất định
    mapping(address => mapping(address => uint256)) private _allowances;

    // khởi tạo các biến private (không thể thay đổi trong contract khác khi import contract ERC20)
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

     // Khởi tạo hàm tạo để set giá trị cho '_name' và '_symbol'
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    // Khởi tạo các hàm virtual override với mục đích ghi đè các hành động ảo 
    // lên các function ở contract cha 


    // Trả về name của token
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    // Trả về symbol của token, 
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    // Giá trị khởi tạo của decimals() là 18
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    //hiện số token ở totalSupply()
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

     // hiện số token ở balanceOf
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    // Gọi hàm transfer và kiểm tra đúng hay sai
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     // gọi hàm allowance và trả về số token trong allowance
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    // Gọi hàm approve và kiểm tra đúng hay sai thông qua _approve() 
    // 'spender' không thể rỗng
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // Tạo hàm Tranfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        // Chuyển 'amount' từ 'sender' sang 'recipient'
        _transfer(sender, recipient, amount);

        // gán số dư hiện tại = số dư của sender và kiểm tra điều kiện
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    // Kiểm tra số lượng token của owner cho phép spender sử dụng tăng lên có thành công hay không
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    // Kiểm tra số lượng token của owner cho phép spender sử dụng giảm xuống có thành công hay không
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        // sender phải khác 0. nếu bằng 0, in ra câu lệnh '...'
        require(sender != address(0), "ERC20: transfer from the zero address");
        // recipient phải khác 0. nếu bằng 0, in ra câu lệnh '...'
        require(recipient != address(0), "ERC20: transfer to the zero address"); 

        // gọi hàm _beforeTokenTransfer (Trước khi Transfer, không có thao tác gì -> hàm rỗng)
        _beforeTokenTransfer(sender, recipient, amount);

        //Tạo 1 biến senderBalance có giá trị bằng _balances với address = 'sender'
        uint256 senderBalance = _balances[sender];  

        //senderBalance phải >= amount, nếu không in ra câu lệnh '...'
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        //Kiểm tra việc 'senderBalance - amount' có xảy ra lỗi hay không
        //Nếu amount > senderBalance --> lỗi 
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        // lượng token của recipient được cộng thêm amount token sau khi chuyển thành công
        _balances[recipient] += amount;

        // Gọi event Transfer thông báo thực hiện giao dịch 
        emit Transfer(sender, recipient, amount);

        // Gọi hàm _afterTokenTransfer (hàm rỗng)
        _afterTokenTransfer(sender, recipient, amount);
    }

  
    // tạo hàm _mint để tạo 'amount' token và chuyển chúng vào 'account' 
    // đồng thời tăng thêm token ở totalSupply
    function _mint(address account, uint256 amount) internal virtual {
        // account phải khác 0, nếu không thì in ra '....'
        require(account != address(0), "ERC20: mint to the zero address");

        // gọi hàm _beforeTokenTransfer (hàm đào token --> sender = address(0))
        _beforeTokenTransfer(address(0), account, amount);

        // totalSupply sẽ được thêm 'amount' token khi đào được
        _totalSupply += amount;

        // account sẽ được nhận 'amount' token
        _balances[account] += amount;

        // Gọi event Transfer để thông báo 
        emit Transfer(address(0), account, amount);

        // gọi hàm _afterTokenTransfer 
        _afterTokenTransfer(address(0), account, amount);
    }

    // Tạo hàm _burn để tiêu 'amount' token từ 'account'
    // đồng thời giảm lượng token ở totalSuppy đi 
    function _burn(address account, uint256 amount) internal virtual {
        
        // các câu lệnh  có mục đích tương tự với các câu lệnh trong function _mint()
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    // Đặt 'amount' làm trợ cấp mới cho 'spender' mà 'owner' cho phép 'spender' sử dụng
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        // yêu cầu ower và spender không thể là rỗng
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        // đặt 'amount' làm trợ cấp mới
        _allowances[owner][spender] = amount;
        
        // gọi event Approval
        emit Approval(owner, spender, amount);
    }

    // trước khi transfer -> không có thao tác gì -> hàm rỗng
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // Sau khi transfer -> không có thao tác gì -> hàm rỗng
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// Tạo 1 Token mới (TokenToday)
contract Tokentoday is ERC20 {
    address public  admin;    // Tạo 1 biến địa chỉ admin

    // Khởi tạo các thông tin ban đầu của token
    // Tên = Ecare 
    // Symbol = EKT
    // Số lượng ban đầu:  10000000* 10 ** 18
    constructor() ERC20 ('ETest','ELHT'){ 
        _mint(msg.sender,10000000* 10 ** 18);
        admin   = msg.sender;
    }
    
    function mint(address to, uint amount) external {
        require ( msg.sender == admin, 'only admin');
        _mint(to, amount);
        
    }
    // Tạo hàm burn --> admin burn 'amount' token
    function burn(uint amount) external { 
        _burn( msg.sender, amount);
    }
    
}
